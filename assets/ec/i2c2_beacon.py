#!/usr/bin/env python3
"""
i2c2_beacon.py -- hammer /dev/i2c-2 so its SCL/SDA pads toggle continuously,
so you can scope-hunt for the physical tap point (no boardview needed).

Drives repeated START+addr to a (likely absent) slave -> steady clock bursts
on SCL, data transitions on SDA. Probe test pads / unpopulated footprints with
a scope (or logic analyzer); the two lines showing ~100kHz bursts = i2c-2.

  sudo python3 i2c2_beacon.py [bus] [addr_hex] [hz]
     bus default 2, addr default 0x28, hz default ~toggle rate cap
Ctrl-C to stop. Purely a bus-master write attempt; harmless to a dedicated bus.
"""
import os, sys, fcntl, time
I2C_SLAVE=0x0703
bus  = int(sys.argv[1]) if len(sys.argv)>1 else 2
addr = int(sys.argv[2],16) if len(sys.argv)>2 else 0x28
fd=os.open(f"/dev/i2c-{bus}",os.O_RDWR)
try: fcntl.ioctl(fd,I2C_SLAVE,addr)
except OSError as e: sys.exit(f"open i2c-{bus}@{addr:#x} failed: {e}")
print(f"beaconing /dev/i2c-{bus} @ 0x{addr:02x} -- scope the pads for clock bursts. Ctrl-C to stop.")
n=0
try:
    while True:
        try: os.write(fd, bytes([0x00, n & 0xff]))   # 2-byte write; NAK ok
        except OSError: pass                          # no slave -> NAK, still clocks
        n+=1
        if n & 0x3ff == 0:
            print(f"\r{n} txns", end="")
except KeyboardInterrupt:
    print("\nstopped"); os.close(fd)
