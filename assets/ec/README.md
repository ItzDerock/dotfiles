# Galaxy Book3 Ultra (960XFH) EC firmware — reverse engineering notes

Extracted from BIOS `P07ALQ` (ITEM_20240619_22402_WIN_P07ALQ.exe, build Apr 11 2024)
for the purpose of understanding the fan-control logic. **Read-only RE; the region
is Intel BIOS Guard signed (`SEC_EC`) and cannot be reflashed via the update path.**

## Files
- `ec_full.bin` — full EC image, base-aligned to the reset vector (132188 B).
  File offset 0 = code address 0x0000 = reset vector `02 0F3E` (LJMP 0x0F3E).
- `ec_bank0.bin` — first 64 KB of `ec_full.bin` = the 8051 code space
  (CODE:0000-FFFF). This is what's imported into Ghidra and analyzed (225 funcs).
- `ec_firmware.bin` — original carve incl. leading RAPTORLAKE config table
  (starts 0x2D bytes before the reset vector; kept for the descriptor table).

## Reset / base (CONFIRMED)
- Original BIOS `main.bin` file offset of reset vector: **0x311fcd**.
- Reset: `CODE:0000 = 02 0F3E` (LJMP 0x0F3E) → `CODE:0F3E = 75 81 35`
  (MOV SP,#0x35, the 8051 stack init) → `LJMP 0x0B99` (= main / task loop).
- Ghidra import: `import_file(ec_bank0.bin, language="8051:BE:16:default")`,
  then `create_function(CODE:0000)` + `run_analysis` → 225 functions,
  decompiler produces clean C (verified: FUN_CODE_0848 is the "ene" firmware-
  header checksum validator).

## BANKING — the open problem for the next session
- Full image is 132 KB but 8051 CODE space is 64 KB. `ec_bank0.bin` (the low
  64 KB) is the fixed/common region. The upper ~66 KB is **banked** and NOT yet
  loaded — most thermal/fan strings' consumers live there (xrefs to the
  `common peci` @0xe1df and `_@TeStMoDe` @0xc587 strings resolve to nothing in
  bank0, i.e. they're called from the banked region).
- NEXT: find the bank-select register (candidate: one of the 0x10xx XRAM writes
  in reset_init, or an SFR) to learn the overlay mapping, then load the upper
  bank(s) as Ghidra overlay blocks and re-run analysis.

## FAN CURVE TABLES FOUND (the payoff)
Banking scheme (CONFIRMED): SFR `0x85` = ROM bank-select; common region
`0x0000-0x7FFF` always mapped; banked 32KB window at `0x8000-0xFFFF`.
Image = common (file 0x0000-0x7FFF) + 3×32KB banked pages (file 0x8000, 0x10000,
0x18000) + 1KB tail. Page at file 0x10000 (bank "1") is a **DATA bank holding
the fan curve tables**. Carved: `ec_win_page1.bin` (data bank), `ec_win_page2.bin`
(a code bank), both = common+page loaded at window 0x8000.

Table format: `0x80`-delimited records. A profile = a temp row + a value row.
Temp row = on/off pairs per fan level. Value row ends `NN 00 TT 00`
(NN=entry count, TT=table/profile id). Decoded (window offsets, bank1):

| @off | on/off temp pairs °C | id |
|------|----------------------|----|
| 8000 | (46/43)(48/45)(50/47)(52/49)(54/51) | 03 |
| 8052 | (65/55)(70/60)(75/65)(80/70) | 04 |
| 8060 | (50/45)(57/52)(62/58)(66/62)(85/83) | 02 |
| 8080 | (46/42)(49/45)(52/48) | 03 (3-entry) |
| ...  | many more profiles (524 records total) | |

- Table id 03, level-1 on@48°C = EXACT match to empirical trip. Confirmed.
- **PWM/value row is 85-95% (e.g. `5f 55` = 95,85).** The LOWEST duty entry in
  the curve is ~85%. THIS is why the fan has no quiet low-speed step — the curve
  simply contains no low-duty setpoint. Min commanded speed ≈ 85% duty = the loud
  3500 RPM floor. Not a bug; the curve was authored with no quiet band.
- Multiple profiles = per platform-profile-mode × sensor. All share the same
  high-duty floor → explains why all 7 ACPI modes sound identical.

## LEVER STATUS (open)
Tables are in a signed ROM data bank (not runtime-writable, BIOS-Guard). The
question that decides whether a software fix exists: does the EC copy the active
threshold into host-writable EC RAM (DSDT exposes `HYST`@0x69, `TSHT`@0x6A,
`TSLT`@0x6B in the ACPI EC space), or read ROM every loop? NOT yet resolved by
RE (consumer is a cross-bank MOVC reader). FASTEST test is on live HW: with
`ec_sys write_support=1`, write `TSHT`/`TSLT`/`HYST` and watch if the trip point
moves. If it sticks → software fan control is possible without reflash.

## Leads found in bank0
- `_@TeStMoDe` (CODE:c587) — likely a hidden EC test/unlock command. Highest-
  value lead for finding a runtime "lever" to change fan behavior.
- `common peci(%d)` (CODE:e1df) — CPU-temp read path (PECI).
- Debug UART logger: `Tick : %05u p80 : %02bX` etc. — EC emits POST/debug codes
  over a UART; could be tapped physically for live tracing.

## Architecture
- **Intel MCS-51 (8051)**, compiled with **Keil C51** (proven by `%02bX`
  format specifier + `?C?` runtime library routines at low code addresses).
- Chip family: **ENE** (same vendor as Book4 Edge KB9058; this is an x86-era
  ENE KB90xx-class 8051 EC).
- Platform string: `RAPTORLAKE`. Build: `Apr 11 2024 15:29:52`.
- Code >64KB ⇒ **banked** code memory (expect bank-switch register writes).

## Ghidra load settings
- Language: `MCS-51 / 8051` (default variant), little-endian.
- Base address `0x0000` for code space. Keil links its runtime library first,
  so `?C?CLDPTR`-style routines sit at low addresses — use them to confirm base:
  in `main.bin` the CLDPTR routine (`BB 01 06 89 82 8A 83 E0 ...`) is at file
  offset `0x312160`, which corresponds to `LCALL 0x0165` seen in the code →
  base ≈ file `0x311FFB`. (For a standalone load of `ec_code.bin`, entry/reset
  is at its offset 0; let auto-analysis + library sigs resolve the rest.)

## Memory-mapped I/O landmarks (this is where the fan logic lives)
- **XRAM `0xEC00` window** — 197 `MOV DPTR,#0xECxx` accesses. This 256-byte page
  is the same buffer Linux reads via `ec_sys` at `/sys/kernel/debug/ec/ec0/io`.
  Known fields (from DSDT `ECR` OperationRegion): `FANS`@0x87 (fan state, 4-bit),
  `TSR1-4`@0x5C-0x5F (thermal sensors; TSR1=chassis SNS1), `CTMP`@0xC0 (CPU temp
  via PECI), `CFSP`@0x66 (fan speed, always 0 = open-loop).
- **XRAM `0x10xx` window** — 198 `MOV DPTR,#0x10xx` accesses. Second register
  bank (GPIO / PWM / internal state).
- Fan RPM values from DSDT (`FANT`): 3500/3810/4420/4730 RPM
  (0x0DAC/0x0EE2/0x1144/0x127A) — NOT found as a literal table in the EC image,
  so the EC likely computes PWM duty directly rather than targeting RPM.

## Empirically established behavior (what RE should explain / find a lever for)
- Fan turns ON when chassis sensor TSR1 crosses **48°C**, OFF at ≤**47°C**.
- Minimum running fan state = 3500 RPM (the loud "100%"); no low-speed idle step.
- Open-loop: EC never reads real fan RPM.
- All 7 ACPI performance modes behave identically at idle.

## RE goals
1. Find the temp→fan-state decision (look for compares against 0x2F/0x30 = 47/48
   near reads of the `0xEC5C` TSR1 register).
2. Determine whether the threshold / curve is read from a **writable** location
   (XRAM/config) that could be poked at runtime — the empirical register probe
   found none, but the code may expose an unlock or command path.
3. Decode the `RAPTORLAKE` descriptor table (offsets 0x0..~0x250 of
   `ec_firmware.bin`) — contains many byte values in the temperature range.
