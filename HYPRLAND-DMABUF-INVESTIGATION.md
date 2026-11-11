# Galaxy: NVIDIA-to-Intel DMA-BUF crash investigation

Investigation captures: 2026-11-06. Status: exact kernel rejection branch identified; no rendering workaround or source fix applied.

## Conclusion

An NVIDIA-exported, 5.5 MiB DMA-BUF is imported by Intel i915 during compositor rendering. NVIDIA's native-memory scatter/gather-table callback sees `pages_count == 0` and explicitly returns `ERR_PTR(-ENOMEM)` before attempting scatterlist allocation. That error propagates through i915's buffer-pinning and execbuffer-submission path.

The original compositor core establishes the userspace consequence: Mesa Iris retries failed submissions, then calls `abort()` inside Hyprland's render-completion/fence path. This explains the freeze followed by a compositor crash.

**The NVIDIA export callback is the proven origin of this error. That does not, by itself, establish which component violated an interoperability contract or should be fixed.** The remaining investigation is why this kind of buffer reaches this export/import path, and how unsupported sharing should be prevented or handled.

The observed `ENOMEM` is not a failed allocation at the identified branch and is not evidence of system-RAM exhaustion.

## Environment and scope

- Host configuration: `galaxy`; NixOS 26.11.
- Kernel: `7.3.0-cachyos-lto`.
- Intel Raptor Lake-P Iris Xe: PCI `0000:00:02.0`, driver `i915`.
- NVIDIA RTX 4070 Max-Q / Mobile: PCI `0000:01:00.0`, open kernel modules `615.78.08`.
- Hyprland v0.57.0, commit `0aa6745f705f2c4b0a5004eb019ef76e5bbdb426`.
- Mesa 26.2.5, Iris rendering driver.
- Original crash report lists hyprexpo `v0.56.2+5`. No plugin frame was identified as the failure origin; plugins have not been independently excluded.
- Two applications reportedly trigger the freeze/crash when their windows appear. Their names, versions, rendering APIs, and launch commands were not established in this investigation.
- `home-manager/overrides/galaxy.nix` already sets `AQ_DRM_DEVICES=/dev/dri/igpu`. Switching the compositor to Intel would not be a new experiment.
- PRIME offload is enabled in `nixos/nvidia.nix`. The Galaxy overrides also define a separate `Firefox Discrete` launcher using `nvidia-offload firefox`; this is configuration context, **not evidence that Firefox is a triggering application or the producer of the failing buffer**.
- The NVIDIA open-module derivation carries a Linux 7.3 PCI-sysfs-access patch in `nixos/nvidia.nix`. No evidence connects that patch to this failure; disclose it in an upstream report.

The original core and later live traces come from different compositor processes. The failure chain below combines the userspace core with subsequent live reproductions; it is not presented as one simultaneous whole-stack capture.

## Decisive runtime evidence

Final capture: `/home/derock/hyprland-gem-trace.log`, lines 62–74, compositor PID 25663, 20:44:12:

```text
dma_buf_map_attachment returned -ENOMEM; pid=25663 tid=25663
exporter=drm size_bytes=5767168 importer_device=0000:00:02.0
map_callback=drm_gem_map_dma_buf pin_callback=0 dynamic_importer=0
known_callback_observed=1
callback_return_signed=-12 callback_return_hex=0xfffffffffffffff4
drm_driver=nvidia-drm exporter_device=0000:01:00.0 get_sg_table=nv_drm_gem_prime_get_sg_table
nvkms_callback_observed=1
nvkms_pages_count=0 nvkms_callback_return=-12
drm_prime_pages_to_sg_observed=0
```

This establishes:

1. The exporting DRM driver is `nvidia-drm`, not just an exporter named `drm`.
2. The importing device is Intel `0000:00:02.0`.
3. NVIDIA's native-memory callback ran with zero pages and returned `-12` (`ENOMEM`).
4. The page-to-scatterlist helper was not reached.

`exporter=drm` alone is not driver identification: `drm_gem_prime_export()` uses the generic DRM module name. The later driver/callback fields provide the identification.

The tracer attached 12 probes and printed `Capture complete; detaching.` Its `-k` warnings about missing map elements correspond to initially absent state/default-zero observations. They are not GPU allocation failures. The native callback/page-count evidence is recorded explicitly.

Earlier live captures established propagation:

- `/home/derock/hyprland-i915-trace.log`, 20:03:54: `i915_gem_object_get_pages_dmabuf`, `i915_vma_pin_ww`, `eb_validate_vmas`, `eb_relocate_parse`, and `i915_gem_execbuffer2_ioctl` all returned `-ENOMEM`.
- `/home/derock/hyprland-dmabuf-trace.log`, 20:36:00, PID 18668: generic DRM map callback returned `-ENOMEM` for the same recorded buffer size and Intel importing device. Buffer identity across separate reproductions was not established by size alone.

## Exact source path and crash mechanism

NVIDIA 615.78.08, `kernel-open/nvidia-drm/nvidia-drm-gem-nvkms-memory.c:371–391`:

```c
static struct sg_table *__nv_drm_gem_nvkms_memory_prime_get_sg_table(
    struct nv_drm_gem_object *nv_gem)
{
    /* ... */
    if (nv_nvkms_memory->pages_count == 0) {
        NV_DRM_DEV_DEBUG_DRIVER(
                nv_dev,
                "Cannot create sg_table for NvKmsKapiMemory 0x%p",
                nv_gem->pMemory);
        return ERR_PTR(-ENOMEM);
    }

    sg_table = nv_drm_prime_pages_to_sg(nv_dev->dev,
                                      nv_nvkms_memory->pages,
                                      nv_nvkms_memory->pages_count);
    return sg_table;
}
```

This is the branch confirmed by the final trace. NVIDIA's object initializer in the same file, lines 405–442, initializes the page count to zero and skips `getMemoryPages()` for video-memory allocations. **[INFERENCE] A video-memory-backed object is consistent with the observation, but `isVidmem()` was not traced for this object; zero pages alone does not prove its allocation type.**

Error propagation and userspace consequence:

```text
NVIDIA native-memory get_sg_table: pages_count == 0 → -ENOMEM
  → nv_drm_gem_prime_get_sg_table
  → drm_gem_map_dma_buf
  → dma_buf_map_attachment
  → i915_gem_object_get_pages_dmabuf
  → i915_vma_pin_ww / eb_validate_vmas / eb_relocate_parse
  → DRM_IOCTL_I915_GEM_EXECBUFFER2 returns ENOMEM
  → Mesa i915_gem_execbuf_ioctl retries with increasing sleeps
  → Mesa Iris _iris_batch_flush ultimately calls abort()
  → Hyprland receives SIGABRT
```

Relevant source locations:

| Component | Source location | Evidence |
| --- | --- | --- |
| NVIDIA | `kernel-open/nvidia-drm/nvidia-drm-gem.c:178–186` | Dispatches to the native object's SG-table callback. |
| Generic DRM | `drivers/gpu/drm/drm_prime.c:666–691` | Calls the object's `get_sg_table`; returns its error, otherwise maps the scatterlist. |
| i915 | `drivers/gpu/drm/i915/gem/i915_gem_dmabuf.c:236–265` | Returns the error from `dma_buf_map_attachment()` unchanged. |
| Mesa | `src/intel/common/i915/intel_gem.h:145–168` | Retries execbuffer `ENOMEM`; prints the observed warning. |
| Mesa | `src/intel/common/intel_gem.h:143–152` | 80 attempts; sleep is `100 * retries * retries` microseconds: 16.748 seconds total scheduled sleep, excluding ioctl/runtime overhead. |
| Mesa | `src/gallium/drivers/iris/iris_batch.c:989–995` | Calls `abort()` for the remaining submission error. |
| Hyprland | `src/render/OpenGL.cpp:2680–2696` | Native-fence `eglCreateSyncKHR()` call in `Render::GL::CEGLSync::create()`. |

The original PID 2896 core, with matching Mesa debug symbols, showed `_iris_batch_flush` returning from submission with `ret = -12`, through `iris_fence_flush`, `tc_flush`, `st_context_flush`, `dri_create_fence_fd`, `dri2_create_sync`, and `eglCreateSyncKHR`, called by Hyprland's render-completion path. The abort occurs inside EGL/Mesa; Hyprland does not receive a normal failed-sync return it could simply check.

Mesa resets batch bookkeeping before aborting. Buffer counts and sizes inspected in that core are post-reset state, not reliable descriptions of the failed submission.

## Which project owns the issue?

| Layer | Proven role | Attribution limit / recommended destination |
| --- | --- | --- |
| NVIDIA | Originates the persistent error when asked to produce an SG table for this object. | First investigation/report target. Public issue #1037 closely matches this deferred cross-GPU failure, and the attach contract requires rejecting inaccessible, non-migratable VRAM. The exact producing API/export route on this machine remains unconfirmed. |
| Intel i915 | Attempts to pin the imported object and propagates NVIDIA's error to execbuffer submission. | No evidence of an independent i915 allocation or mapping defect. Not the first target merely because the ioctl is an i915 ioctl. |
| Mesa Iris | Treats `ENOMEM` as retryable, stalls the rendering thread, then aborts the compositor process. | Separate robustness/error-classification investigation. A recoverable alternative is not established; suppressing `abort()` or ignoring submission failure would not be a demonstrated fix. |
| Hyprland / graphics integration | Consumes the buffer and reaches the EGL fence operation that flushes pending work. | Possible role in buffer selection, import validation, or advertised capabilities, but not proven. Its visible crash is caused by Mesa's abort. Preserve this context in a downstream report rather than assigning primary fault from the process name. |
| Producing client / graphics userspace | Selected or exported the object through a path that ends in the NVIDIA native-memory callback. | Producer PID, API, allocator, and export method remain unidentified. The application whose window triggers the failure is not automatically proven to own the offending buffer. |

DMA-BUF's `map_dma_buf` contract permits error-pointer returns (`include/linux/dma-buf.h:154–163`). Finding the return site therefore does not itself prove an API-contract violation by NVIDIA. The compatibility failure and the fatal handling are separate questions.

## Follow-up: blame history and rationale

### What public blame establishes

| Date / release | Commit | Change at this branch |
| --- | --- | --- |
| 2022-05-09 / 515.43.04 | [`1739a20efc4a`](https://github.com/NVIDIA/open-gpu-kernel-modules/commit/1739a20efc4acb55fd1dc53dcc66057b70c2613c) | The first public source import already contains the `pages_count == 0` guard and diagnostic, but returns `NULL`. This is the earliest public evidence, not necessarily the date NVIDIA originally implemented the guard. |
| 2023-03-23 / 530.41.03 | [`6dd092ddb7c1`](https://github.com/NVIDIA/open-gpu-kernel-modules/commit/6dd092ddb7c165fb1ec48b937fa6b33daa37f9c1) | Changes exactly `return NULL;` to `return ERR_PTR(-ENOMEM);` in this function. |
| 2024-10-22 / 565.57.01 | [`d5a0858f901d`](https://github.com/NVIDIA/open-gpu-kernel-modules/commit/d5a0858f901d15bda4c3d6db19a271507722a860) | Changes this diagnostic from `NV_DRM_DEV_LOG_ERR` to `NV_DRM_DEV_DEBUG_DRIVER`; the rejection remains. This explains why default kernel logging need not expose the failure. |

The public commit messages are release numbers, not feature-level explanations. NVIDIA's README explicitly says the repository is mostly a [snapshot per driver release](https://github.com/NVIDIA/open-gpu-kernel-modules/blob/6dd092ddb7c165fb1ec48b937fa6b33daa37f9c1/README.md#how-to-contribute), without internal per-change history. No public author explanation for choosing `ENOMEM` rather than another error code was found. **[INFERENCE]** The 2023 change corrects the error representation expected by the caller; it does not implement previously missing cross-GPU mapping support.

### Technical reason for the guard

This particular NVIDIA native-GEM export implementation constructs an SG table from an array of Linux `struct page *` objects. Its initializer skips fetching that array for video-memory allocations. A zero page count therefore means that this implementation has no page array to describe to the importing driver; it does not mean the allocated buffer is zero bytes or that RAM allocation just failed. The generic `drm_prime_pages_to_sg()` helper requires that array.

The source also contains a distinct `nv_dma_buf_map()` implementation in `kernel-open/nvidia/nv-dmabuf.c:1110–1147`, which chooses page-based or PFN-based mapping depending on the allocation. Our trace used the generic DRM/native-GEM callback, **not** that alternate mapper. The limitation must not be generalized to “all NVIDIA DMA-BUF exports require system-memory pages.”

Removing the guard, returning success, or treating a GPU address as a normal RAM page would not supply a valid mapping. A real solution needs a supported peer mapping, migration/copy to accessible memory, or rejection early enough for the consumer to select another path.

### Existing upstream report and the earlier-rejection contract

[NVIDIA/open-gpu-kernel-modules #1037 — Buffers created using GBM are not usable when imported into non-Nvidia drivers](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1037) was open when inspected. It contains:

- A standalone GBM-to-EGL reproducer: import succeeds, then actual sampling/submission on another GPU fails.
- The same Intel `execbuf ioctl keeps returning ENOMEM` warning and NVIDIA SG-table diagnostic.
- A later Intel/NVIDIA/Hyprland report with the same EGL fence stack and SIGABRT, plus a separate AMD/NVIDIA trace locating the error in the NVIDIA callback.
- Discussion identifying missing VRAM migration/peer-mapping support and failure to reject an unsupported attachment as the suspected exporter defect. These explanations are contributor analysis, not a verified NVIDIA fix or an admission by NVIDIA.

The [kernel DMA-BUF attach contract](https://docs.kernel.org/driver-api/dma-buf.html#c.dma_buf_ops), also present in the matching local `include/linux/dma-buf.h:39–51`, says exporters with VRAM or carveout buffers should verify that the importing device can access the buffer, or that the buffer can move to system memory; otherwise attachment must fail. Permission to return mapping errors does not remove this earlier compatibility check.

In our generic DRM path, `drm_gem_map_attach()` checks for a `get_sg_table` callback and invokes an optional GEM pin callback. It does not itself verify that NVIDIA's native object can provide a page list. The upstream issue mentions `nv_dma_buf_attach()`, but that name should not be substituted for the generic DRM attachment helper relevant to this export path.

This strengthens the NVIDIA-side attribution beyond simply finding where `ENOMEM` originates: unsupported sharing appears to be accepted and discovered too late. The exact client allocation/export route still needs correlation before declaring this machine's reproduction identical to the issue's GBM case.

The older [NVIDIA forum thread](https://forums.developer.nvidia.com/t/550-54-14-cannot-create-sg-table-for-nvkmskapimemory-spammed-when-launching-chrome-on-wayland/284775) was tracked as internal bug 4545633. NVIDIA's October 2024 reply attributed the hang elsewhere and linked [Chromium issue 351095641](https://issues.chromium.org/issues/351095641); its contents were not accessible through the unauthenticated reader. That historical response is not proof that the present driver-independent GBM reproducer or our trace is a Chromium bug.


## Recommended next steps, in order

### 1. Preserve and report the current evidence; no new crash required

Add the existing runtime evidence to [NVIDIA issue #1037](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1037) first, rather than starting with a duplicate report. A focused title for a separate report, if maintainers request one:

> NVIDIA 615.78.08: zero-page NvKms GEM object returns ENOMEM on PRIME export to Intel i915; Mesa Iris retries then aborts compositor

Include the excerpt above, source branch, environment, two trigger applications and exact versions/launch commands once identified, and the existing downstream crash stack. Disclose the custom kernel and NVIDIA module patch without assuming either is responsible. Ask whether this allocation/export route is supported for Intel imports, and where rejection or fallback should occur.

NVIDIA's source README directs open-module-specific issues to [NVIDIA/open-gpu-kernel-modules](https://github.com/NVIDIA/open-gpu-kernel-modules/issues), and general Linux driver issues to [its Linux forum](https://forums.developer.nvidia.com/c/gpu-graphics/linux/148). Do not upload a raw compositor core publicly: it can contain credentials and other process memory. Review any vendor diagnostic bundle before sharing it.

A related Mesa report can focus on the deterministic `ENOMEM` retry stall and fatal process abort; link the NVIDIA report rather than conflating the two questions. Follow [Mesa's reporting guidance](https://docs.mesa3d.org/bugs.html).

### 2. Identify the buffer's producer and export route

If another controlled capture is worthwhile, extend tracing at export/allocation time, not just farther down the already-identified rejection path:

- Observe `drm_gem_prime_export()` / `dma_buf_export()` in relevant processes, not only the Hyprland PID.
- Correlate the exported DMA-BUF with the failing import using its identity and lifetime, such as its inode with lifetime tracking. Size alone is not identity; kernel addresses can also be reused.
- Record producer PID/command, launch environment/offload selection, rendering API, and allocation/export method.
- Obtain buffer format, dimensions, modifier, and relevant Wayland DMA-BUF negotiation from client/protocol diagnostics where available.

This distinguishes a driver allocation/export limitation from an unsuitable userspace route or capability-negotiation problem. Collect these metadata without changing kernel/render settings first. Any deliberate trigger can still crash the session; keep tracing outside the graphical session as before.

### 3. Start with the existing faithful reproducer

Issue #1037 already provides a [standalone GBM-export / EGL-sampling reproducer](https://gist.github.com/hoshinolina/9d0731cba9fad23562dda90106178cf8). Its source was inspected but it was not built or run here. It exercises actual sampling and flush, not just import; executing it may still stall or disrupt graphics, so do not launch it automatically in the active desktop session. If a controlled reproduction is authorized later, compare its callback result with our captured zero-page failure before writing another reproducer. If the applications use a different export route, reduce that route separately.

### 4. Use controlled comparisons only when they answer an ownership question

If maintainers need comparisons, vary one component at a time: a matched NVIDIA kernel/userspace driver release, Mesa, then compositor/integration behavior. Record both the callback result and whether the compositor survives. NVIDIA kernel and userspace versions must remain matched. Schedule any required session restart; there is no need to change kernels or repeatedly log out just to inspect the current evidence.

Do not start with random kernel switches, modifier/explicit-sync flags, plugin removal, or forcing the compositor to Intel. Those changes are not established fixes, and the compositor is already configured for Intel. An application-local single-GPU comparison could later isolate cross-GPU involvement, but would be a diagnostic control, not a permanent solution.

## Evidence and source preservation

Raw captures remain outside the repository. This report embeds the decisive result so the conclusion does not depend on those files remaining at their current paths.

| Artifact | Local path |
| --- | --- |
| Session stderr/stdout | `/home/derock/hyprland-session.log` |
| Original GDB transcript | `/home/derock/coredump-full.txt` |
| Original crash report | `/home/derock/.cache/hyprland/hyprlandCrashReport2896.txt` |
| Kernel propagation trace | `/home/derock/hyprland-i915-trace.log` |
| Generic callback trace | `/home/derock/hyprland-dmabuf-trace.log` |
| Driver and zero-page branch trace | `/home/derock/hyprland-gem-trace.log` |
| Final tracing program | `/home/derock/hyprland-dmabuf.bt` |

SHA-256 fingerprints at documentation time:

```text
702da54883eb2eaf1c0f312bfa55c8ab7012ae7a434f3afc961ffefd907f1842  hyprland-session.log
3a000ae4473d56ae3690c56f635a2bd4af7e2db9309c41f3e04ed7064c6fa228  coredump-full.txt
0e1ffa17fe419d656f51e55a9c3dc8c7fbd1d221efb37435400eab99cf206917  hyprland-i915-trace.log
05266500aefbe431d85ae3005611af96dea458a6bcadcff4bbb47036b34f0be1  hyprland-dmabuf-trace.log
2fbda87b7acdaa1ceab8834bfe58b19a4a7bfef4c4d5eb1c223ce8ccc925ee3d  hyprland-gem-trace.log
4e07526b5b23aeb6d27d59d10667a90131c34328a0180d9e1f21e09861bb7a20  hyprland-dmabuf.bt
```

Matching local source snapshots used for source attribution:

```text
NVIDIA: /nix/store/cxd077nd2p5bj0sani78s07kd2dh5s3s-source
Kernel: /nix/store/ms54r60yz2gv0lbmn5wfznh1r07hhxxk-linux-src-patched
Mesa:   /nix/store/hnsb15znq9rmdrbx357iqmsvl0w3hw6s-source
Hyprland: /nix/store/jmq05ghn07gi933h0jdxxjfby6lyiknz-source
```

Nix store source snapshots can be garbage-collected unless otherwise retained. Preserve the relevant source revision and local patch with any long-lived upstream report. No new crash reproductions, system activation, kernel switch, application GPU-selection changes, or source fixes were performed while writing this report.
