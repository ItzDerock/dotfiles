#!/usr/bin/env python3
"""
ec_mbox_hunt.py -- (1) prove WTMX writes via a HARMLESS scratch byte, then
(2) find the fan register by correlating EC XRAM against fan state.

Subcommands:
  writetest   Write/read-back a mailbox SCRATCH buffer byte (0xF485).
              This byte is command-argument scratch, not a live peripheral
              register -> safe, reversible, proves WTMX works.

  hunt        Continuously snapshot EC XRAM via the mailbox AND the true fan
              state (FANS @ ACPI-EC 0x87 via ec_sys). Reports which XRAM
              addresses track the fan turning on/off. READ-ONLY on EC regs.
              Run it, then let the fan go through at least one ramp+off cycle
              (or run `stress-ng --cpu 8` to force it on), then Ctrl-C.

Usage:
  sudo python3 ec_mbox_hunt.py writetest
  sudo python3 ec_mbox_hunt.py hunt          # Ctrl-C after a fan cycle
"""
import os, sys, time

ECM1, ECM2, ECM3 = 0x0A01, 0x0A02, 0x0A03
EC_SYS = "/sys/kernel/debug/ec/ec0/io"

def _p():        return os.open("/dev/port", os.O_RDWR)
def outb(fd,p,v):os.lseek(fd,p,0); os.write(fd,bytes([v&0xff]))
def inb(fd,p):   os.lseek(fd,p,0); return os.read(fd,1)[0]

def rdmx(fd,a):
    outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); return inb(fd,ECM3)
def wtmx(fd,a,v):
    outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); outb(fd,ECM3,v&0xff)

def fans():
    # true fan state: FANS nibble @ ACPI-EC offset 0x87 (needs ec_sys loaded)
    with open(EC_SYS,"rb") as f:
        f.seek(0x87); return f.read(1)[0] & 0x0f

def writetest():
    fd=_p()
    A=0xF485                      # scratch slot inside mbox arg buffer
    orig=rdmx(fd,A)
    for tv in (0x5a,0xa5,orig):
        wtmx(fd,A,tv); rb=rdmx(fd,A)
        print(f"  wrote 0x{tv:02x} -> read 0x{rb:02x}  {'OK' if rb==tv else 'MISMATCH'}")
    print(f"restored 0x{orig:02x}. If all OK, WTMX writes work.")
    os.close(fd)

def hunt():
    fd=_p()
    # scan window: default peripheral zones. override: argv[2]=lo argv[3]=hi (hex)
    LO=int(sys.argv[2],16) if len(sys.argv)>2 else 0xFC00
    HI=int(sys.argv[3],16) if len(sys.argv)>3 else 0x10000
    on_samples=[]; off_samples=[]
    print("Sampling... trigger a fan ramp (or run stress-ng), Ctrl-C when done.")
    try:
        while True:
            fs=fans()
            snap=bytes(rdmx(fd,a) for a in range(LO,HI))
            (on_samples if fs>=1 else off_samples).append(snap)
            print(f"\rFANS={fs}  on={len(on_samples)} off={len(off_samples)}",end="")
            time.sleep(0.5)
    except KeyboardInterrupt:
        pass
    print()
    if not on_samples or not off_samples:
        print("Need BOTH fan-on and fan-off samples. Re-run through a full cycle.")
        os.close(fd); return
    # For each address, compare typical value on vs off
    import statistics
    def med(samps,i): return statistics.median(s[i] for s in samps)
    print("\nAddresses that differ most between fan-ON and fan-OFF:")
    rows=[]
    for i,a in enumerate(range(LO,HI)):
        mon,moff=med(on_samples,i),med(off_samples,i)
        if mon!=moff:
            rows.append((abs(mon-moff),a,moff,mon))
    rows.sort(reverse=True)
    for d,a,moff,mon in rows[:25]:
        print(f"  0x{a:04x}: off={moff:.0f}  on={mon:.0f}  (Δ{d:.0f})")
    print("\nFan PWM/level register = one that is ~0 when off and jumps when on,")
    print("or holds a duty value (85-95, or ~scaled). Report the top hits.")
    os.close(fd)

if __name__=="__main__":
    if os.geteuid()!=0: sys.exit("run as root")
    cmd=sys.argv[1] if len(sys.argv)>1 else ""
    if cmd=="writetest": writetest()
    elif cmd=="hunt": hunt()
    else: sys.exit(__doc__)
