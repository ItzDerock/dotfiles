#!/usr/bin/env python3
"""
ec_fancmd.py -- try the Book4 manual-fan OVERRIDE commands via our mailbox.

Mailbox (DSDT CMDD): args -> 0xF480+, trigger = WTMX(0xFF10, cmd), wait 0xFF10==0.

  probe            send FANZONE(0x08) levels 15..0 + FANRPM(0x17), watch RPM/duty
  cmd C A0 A1..    send one command C with arg bytes (all hex), show fan

Fan cmds only. Plugged in. Ctrl-C / reboot = safe reset.
"""
import os, sys, time
ECM1,ECM2,ECM3=0x0A01,0x0A02,0x0A03
def _p(): return os.open("/dev/port",os.O_RDWR)
def outb(fd,p,v): os.lseek(fd,p,0); os.write(fd,bytes([v&0xff]))
def inb(fd,p): os.lseek(fd,p,0); return os.read(fd,1)[0]
def rd(fd,a): outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); return inb(fd,ECM3)
def wr(fd,a,v): outb(fd,ECM1,(a>>8)&0xff); outb(fd,ECM2,a&0xff); outb(fd,ECM3,v&0xff)
def duty(fd): return rd(fd,0xfe23)     # inverted: 255=stopped, lower=faster
def tach(fd): return rd(fd,0xfc02)

def ckid(fd):                          # wait EC ready (0xFF10==0)
    for _ in range(3000):
        if rd(fd,0xFF10)==0: return True
        time.sleep(0.001)
    return False

def send(fd,cmd,args):
    if not ckid(fd): print("  EC busy"); return
    for i,b in enumerate(args): wr(fd,0xF480+i,b)   # SNDA: args -> 0xF480+
    wr(fd,0xFF10,cmd)                                # trigger
    ckid(fd)                                         # wait done

def probe():
    fd=_p()
    print(f"baseline duty(fe23)=0x{duty(fd):02x} tach=0x{tach(fd):02x}")
    for lv in (15,10,5,2,0):
        send(fd,0x08,[lv]); time.sleep(1.5)
        print(f"FANZONE {lv:2d} -> duty=0x{duty(fd):02x} tach=0x{tach(fd):02x}")
    for rpmv in (0x0BB8,0x1388,0x0000):   # 3000,5000,auto
        send(fd,0x17,[0,0,(rpmv>>8)&0xff,rpmv&0xff]); time.sleep(1.5)
        print(f"FANRPM {rpmv} -> duty=0x{duty(fd):02x} tach=0x{tach(fd):02x}")
    send(fd,0x08,[0])                     # release to auto
    print("released (FANZONE 0). listen: did fan change at any step?")
    os.close(fd)

def cmd():
    fd=_p(); c=int(sys.argv[2],16); a=[int(x,16) for x in sys.argv[3:]]
    print(f"pre duty=0x{duty(fd):02x} tach=0x{tach(fd):02x}")
    send(fd,c,a); time.sleep(1.5)
    print(f"post duty=0x{duty(fd):02x} tach=0x{tach(fd):02x}")
    os.close(fd)

if __name__=="__main__":
    if os.geteuid()!=0: sys.exit("root")
    m=sys.argv[1] if len(sys.argv)>1 else ""
    if m=="probe": probe()
    elif m=="cmd": cmd()
    else: sys.exit(__doc__)
