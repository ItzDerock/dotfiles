#!/usr/bin/env python3
"""
ec_fan.py -- inspect + test the EC fan block (0xF300) via ECMB mailbox ports.

  dump              read 0xF300..0xF31F once, decode tach
  watch             live 0xF300..0xF30F + RPM, 0.5s, Ctrl-C to stop
  setduty REG VAL   WTMX(0xF3RR, VAL); hold+monitor RPM 8s; report if it
                    STICKS or the EC curve loop reverts it. REG e.g. 05.

Fan-controller block only (not power/flash). A reboot fully resets the EC.
Run plugged in; keep temps in view.
"""
import os, sys, time
ECM1, ECM2, ECM3 = 0x0A01, 0x0A02, 0x0A03
def _p(): return os.open("/dev/port", os.O_RDWR)
def outb(fd,p,v): os.lseek(fd,p,0); os.write(fd,bytes([v&0xff]))
def inb(fd,p): os.lseek(fd,p,0); return os.read(fd,1)[0]
def rd(fd,a): outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); return inb(fd,ECM3)
def wr(fd,a,v): outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); outb(fd,ECM3,v&0xff)
def tach(fd):
    hi,lo = rd(fd,0xf307), rd(fd,0xf306)
    return (hi<<8)|lo

def dump():
    fd=_p()
    row=[rd(fd,0xf300+i) for i in range(0x20)]
    for i in range(0,0x20,8):
        print(f"  f3{i:02x}: "+' '.join(f'{row[i+j]:02x}' for j in range(8)))
    print(f"  tach(f306/07 raw16) = {tach(fd)}")
    os.close(fd)

def watch():
    fd=_p()
    try:
        while True:
            r=[rd(fd,0xf300+i) for i in range(0x10)]
            print("\rf300-0f: "+' '.join(f'{x:02x}' for x in r)+f"  rpm16={tach(fd)}   ",end="")
            time.sleep(0.5)
    except KeyboardInterrupt: print()
    os.close(fd)

def setduty(reg,val):
    fd=_p(); a=0xf300+reg
    orig=rd(fd,a)
    print(f"orig f3{reg:02x}=0x{orig:02x}  writing 0x{val:02x}")
    print("t   f3RR  rpm16")
    wr(fd,a,val)
    for k in range(16):
        cur=rd(fd,a); print(f"{k*0.5:4.1f} 0x{cur:02x}  {tach(fd)}")
        if k==0 and cur!=val: print("  (reverted immediately)")
        time.sleep(0.5)
    print(f"restore f3{reg:02x}=0x{orig:02x}"); wr(fd,a,orig)
    os.close(fd)

def watchpwm():
    fd=_p()
    try:
        while True:
            r=[rd(fd,0xfe20+i) for i in range(4)]
            print("\rfe20-23: "+' '.join(f'{x:02x}' for x in r)+f"  rpm~{rd(fd,0xfc02)}   ",end="")
            time.sleep(0.4)
    except KeyboardInterrupt: print()
    os.close(fd)

def hold(addr,val,secs):
    # continuously re-assert ADDR=VAL to beat the curve loop; monitor
    fd=_p(); orig=rd(fd,addr)
    print(f"orig 0x{addr:04x}=0x{orig:02x}. holding =0x{val:02x} for {secs}s (Ctrl-C stops)")
    t0=time.time()
    try:
        while time.time()-t0<secs:
            wr(fd,addr,val)
            rb=rd(fd,addr)
            print(f"\r wrote0x{val:02x} read0x{rb:02x} fe23=0x{rd(fd,0xfe23):02x} tachcap=0x{rd(fd,0xfc02):02x}  ",end="")
            time.sleep(0.1)
    except KeyboardInterrupt: pass
    print(f"\nrestore 0x{addr:04x}=0x{orig:02x}"); wr(fd,addr,orig)
    os.close(fd)

if __name__=="__main__":
    if os.geteuid()!=0: sys.exit("root")
    c=sys.argv[1] if len(sys.argv)>1 else ""
    if c=="dump": dump()
    elif c=="watch": watch()
    elif c=="watchpwm": watchpwm()
    elif c=="setduty": setduty(int(sys.argv[2],16),int(sys.argv[3],16))
    elif c=="hold": hold(int(sys.argv[2],16),int(sys.argv[3],16),float(sys.argv[4]) if len(sys.argv)>4 else 10)
    else: sys.exit(__doc__)
