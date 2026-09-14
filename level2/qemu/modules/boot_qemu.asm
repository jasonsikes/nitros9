********************************************************************
* Boot - QEMU virt-disk bootstrap
*
* Called from Krn F$Boot. Reads LSN 0 of /D0, allocates DD.BSZ bytes, loads
* that many contiguous sectors from DD.BT, returns the buffer to Krn.
* Contiguous OS9Boot only (DD.BSZ must be non-zero).
*

         nam   Boot
         ttl   QEMU virt disk bootstrap

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Systm+Objct
atrv     set   ReEnt+rev
rev      set   $01
edition  set   1
size     equ   0               no static storage; frame is on the stack

         mod   eom,name,tylg,atrv,start,size

name     fcs   /Boot/
         fcb   edition

* Stack frame. LSN0 scratch sits above the scalars.
bootptr  equ   0               pointer to F$BtMem allocation
lsn      equ   2               24-bit LSN currently being read
bootsiz  equ   5               DD.BSZ (OS9Boot size in bytes)
nsect    equ   7               sector count (DD.BSZ+255)/256
lsn0     equ   8               256-byte LSN 0 buffer
FRAMSIZ  equ   8+256

*------------------------------------------------------------
*
* Boot
*
* Entry:
* Called from Krn F$Boot
*
* Exit:
* X = address of OS9Boot in memory
* D = size in bytes (DD.BSZ)
* CC = carry set on error
* B = error code
*
start    orcc  #$50            IRQ and FIRQ off
         leas  -FRAMSIZ,s      vars + 256-byte LSN0 buffer
         leau  lsn0,s          U -> LSN0 scratch
         clra                  LSN 0 (bits 23-16)
         ldx   #0              LSN 0 (bits 15-0)
         bsr   Read
         bcs   Fail

         ldd   DD.BSZ,u        OS9Boot size; 0 means fragmented
         beq   NoBoot          this booter is contiguous-only
         std   bootsiz,s
         lda   DD.BT,u         start LSN of OS9Boot (MSB)
         sta   lsn,s
         ldd   DD.BT+1,u       start LSN (LSW)
         std   lsn+1,s

         ldd   bootsiz,s
         addd  #$00FF          round up; sector count in A
         sta   nsect,s
         ldd   bootsiz,s
         os9   F$BtMem         allocate D bytes; U = buffer
         bcs   Fail
         stu   bootptr,s

Load     lda   lsn,s           LSN bits 23-16
         ldx   lsn+1,s         LSN bits 15-0
         bsr   Read            U is the current fill pointer
         bcs   RdFail
         leau  256,u           next sector in the bootfile
         inc   lsn+2,s         24-bit LSN + 1
         bne   Nxt
         inc   lsn+1,s
         bne   Nxt
         inc   lsn,s
Nxt      dec   nsect,s
         bne   Load

         ldx   bootptr,s       return buffer to Krn
         ldd   bootsiz,s
         leas  FRAMSIZ,s
         andcc #$FE            clear carry
         rts

NoBoot   ldb   #E$Sect         DD.BSZ was zero
Fail     orcc  #1
         leas  FRAMSIZ,s
         rts

* B is on the stack, so bootptr/bootsiz offsets are +1
RdFail   pshs  b               preserve virt-disk error
         ldu   bootptr+1,s
         ldd   bootsiz+1,s
         os9   F$SRtMem        give back the bootfile pages
         puls  b
         bra   Fail

*------------------------------------------------------------
*
* Read one 256-byte sector from /D0 via $FF30
*
* Entry:
* A:X = LSN
* U = 256-byte CPU buffer
*
* Exit:
* CC = carry set on error
* B = error code
* A, X, U restored on success
*
Read     pshs  a,x,u
         ldx   #Q.PORT
         lda   Q.MAGIC,x
         cmpa  #'Q
         bne   NoDev           virt disk not present
         lda   #QD.D0          OS9Boot lives on /D0
         sta   Q.DRV,x
         lda   ,s              LSN bits 23-16
         sta   Q.LSN,x
         ldd   1,s             LSN bits 15-0
         std   Q.LSN+1,x
         ldd   3,s             buffer
         std   Q.BUF,x
         lda   #QCMD.RD
         sta   Q.CMD,x         QEMU copies the sector now
         ldb   Q.STAT,x
         bne   RdErr
         clrb                  clear carry
         puls  a,x,u,pc
RdErr    leas  5,s             drop saved A,X,U; B is Q.STAT
         orcc  #1
         rts
NoDev    leas  5,s
         comb
         ldb   #E$NotRdy
         rts

* L2 kernel file is rel, boot, krn. REL jumps to krn at $F000, so Boot
* must occupy $EE30-$EFFF ($1D0 bytes) like boot_1773. 3 is emod.
Filler   fill  $39,$1D0-3-*

         emod
eom      equ   *
         end
