#!/usr/bin/env python3
"""
ec_mbox_probe.py  --  READ-ONLY validation of the Samsung Galaxy Book3 Ultra
EC I/O-port mailbox (ECMB @ SystemIO 0x0A00), decoded from DSDT methods
RDMX/WTMX/CMDD/CDRD and cross-referenced with the Book4-Edge RE.

This script ONLY reads. It performs no writes to EC registers beyond the
mailbox address latches (ECM1/ECM2) required to address a read, exactly as
the firmware's own RDMX does. It does NOT issue any command strobe.

Ports (ECMB field ECM0..ECM3 = 0xA00..0xA03):
  RDMX(addr16): ECM1 = addr>>8 ; ECM2 = addr&0xff ; return ECM3
  WTMX(addr16,v): ECM1 = addr>>8 ; ECM2 = addr&0xff ; ECM3 = v   (NOT used here)

Run: sudo python3 ec_mbox_probe.py
"""
import os, sys, time, struct

ECM0, ECM1, ECM2, ECM3 = 0x0A00, 0x0A01, 0x0A02, 0x0A03

def _port_open():
    # /dev/port: byte at file offset N == I/O port N (needs root, CAP_SYS_RAWIO)
    return os.open("/dev/port", os.O_RDWR)

def outb(fd, port, val):
    os.lseek(fd, port, os.SEEK_SET)
    os.write(fd, bytes([val & 0xff]))

def inb(fd, port):
    os.lseek(fd, port, os.SEEK_SET)
    return os.read(fd, 1)[0]

def rdmx(fd, addr):
    """Mirror of DSDT RDMX: read EC register at 16-bit addr. Read-only."""
    outb(fd, ECM1, (addr >> 8) & 0xff)
    outb(fd, ECM2, addr & 0xff)
    return inb(fd, ECM3)

def main():
    if os.geteuid() != 0:
        sys.exit("must run as root")
    fd = _port_open()

    # 1) Mailbox-ready check (DSDT CKID polls RDMX(0xFF10)==0 when EC idle)
    cmd_reg = rdmx(fd, 0xFF10)
    print(f"[cmd reg 0xFF10] = 0x{cmd_reg:02x}   (0x00 => EC idle/ready, mailbox alive)")

    # 2) Read the mailbox data buffer window 0xF480.. (should be stable/zero-ish)
    buf = [rdmx(fd, 0xF480 + i) for i in range(8)]
    print(f"[mbox buf 0xF480..0xF487] = {' '.join(f'{b:02x}' for b in buf)}")

    # 3) Scan a chunk of EC XRAM looking for plausible temperature bytes
    #    (0x28..0x5a == 40..90 C). Correlate later with real sensors.
    print("\nScanning 0xF000..0xF0FF for temp-like values (40-90 C):")
    hits = []
    for a in range(0xF000, 0xF100):
        v = rdmx(fd, a)
        if 0x28 <= v <= 0x5a:
            hits.append((a, v))
    for a, v in hits[:40]:
        print(f"  0x{a:04x} = {v} C?")
    print(f"  ({len(hits)} candidate bytes)")

    # 4) Sanity: read twice, 1s apart, report which addresses CHANGE
    print("\nDelta scan 0xF000..0xF1FF (2 reads, 1s apart) -- changing bytes:")
    first = {a: rdmx(fd, a) for a in range(0xF000, 0xF200)}
    time.sleep(1.0)
    for a in range(0xF000, 0xF200):
        v2 = rdmx(fd, a)
        if v2 != first[a]:
            print(f"  0x{a:04x}: {first[a]} -> {v2}")

    os.close(fd)
    print("\nDone (read-only). If 0xFF10 read 0x00 and buffer/temps look sane,")
    print("the mailbox backdoor is live and writable via WTMX.")

if __name__ == "__main__":
    main()
