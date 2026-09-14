********************************************************************
* Clock2 - QEMU virt RTC driver
*
* Reads the 6-byte OS-9 time packet. Clock calls GetTime
* about one second after F$STime and once a minute after that.
* SetTime is a no-op; the host clock is the source of truth.
*

         nam   Clock2
         ttl   QEMU virt RTC

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Sbrtn+Objct
atrv     set   ReEnt+rev
rev      set   $00
edition  set   1
size     equ   0               no static storage

         mod   eom,name,tylg,atrv,start,size

name     fcs   /Clock2/
         fcb   edition

* Clock jsr $00 / $03 / $06 (Init / GetTime / SetTime).
* Init falls into GetTime so the first tick already has host time.
start    bra   GetTime
         nop
         bra   GetTime
         nop
         rts                   SetTime: writes ignored

*------------------------------------------------------------
*
* GetTime
*
* Entry:
* Called from Clock (jsr $03,x) and from Init (jsr ,y)
*
* Exit:
* D.Year through D.Sec hold host time if the virt RTC is present;
* D.Time is left unchanged if it is not
*
GetTime  ldx   #R.PORT
         lda   R.MAGIC,x       'Q'; also latches a coherent packet
         cmpa  #'Q
         bne   Done            virt RTC not present
         ldd   R.YEAR,x        YY MM
         std   <D.Year
         ldd   R.DAY,x         DD HH
         std   <D.Day
         ldd   R.MIN,x         MM SS
         std   <D.Min
Done     rts

         emod
eom      equ   *
         end
