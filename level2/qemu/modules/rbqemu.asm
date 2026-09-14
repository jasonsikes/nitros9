********************************************************************
* RBQemu - QEMU virt-disk RBF driver
*
* One 256-byte sector per Read/Write. LSN in B:X, buffer in PD.BUF.
* No IRQ; QEMU finishes the copy in the command write.
*

         nam   RBQemu
         ttl   QEMU virt RBF disk

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Drivr+Objct
atrv     set   ReEnt+rev
rev      set   $01
edition  set   2
size     equ   DRVBEG+(DRVMEM*Q.NDRV)  drive tables for Q.NDRV units

         mod   eom,name,tylg,atrv,start,size

         fcb   DIR.+SHARE.+PREAD.+PWRIT.+PEXEC.+READ.+WRITE.+EXEC.
name     fcs   /RBQemu/
         fcb   edition

* RBF driver entry table
start    lbra  Init
         lbra  Read
         lbra  Write
         lbra  GetStat
         lbra  SetStat
         lbra  Term

*------------------------------------------------------------
*
* Init
*
* Entry:
* Y = address of device descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
* V.PORT already holds $FF30 from the descriptor. Each drive table
* needs a non-zero DD.TOT so RBF will allow an LSN 0 read; geometry
* is filled in from that sector on the first Read.
*
Init     lda   #Q.NDRV
         sta   V.NDRV,u
         leax  DRVBEG,u        first drive table
         ldb   #Q.NDRV
InitDrv  lda   #1
         sta   DD.TOT+2,x      non-zero so LSN 0 can be read
         leax  DRVMEM,x        next drive table
         decb
         bne   InitDrv
         clrb
         rts

*------------------------------------------------------------
*
* Read
*
* Entry:
* B:X = LSN
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
* After a successful transfer of LSN 0, copy DD.SIZ bytes from the
* sector buffer into that unit's drive table so RBF has geometry.
*
Read     pshs  b,x,y,u
         lda   #QCMD.RD
         bsr   Xfer
         bcs   RdErr
         lda   ,s              LSN bits 23-16
         bne   RdOK            not LSN 0
         ldd   1,s             LSN bits 15-0
         bne   RdOK
         ldy   3,s             path descriptor
         ldu   5,s             static storage
         ldx   PD.BUF,y        sector just read
         lda   PD.DRV,y        unit number
         ldb   #DRVMEM
         mul                   offset of this unit's drive table
         leay  DRVBEG,u
         leay  d,y
         ldb   #DD.SIZ         bytes RBF keeps from LSN 0
RdLSN0   lda   ,x+
         sta   ,y+
         decb
         bne   RdLSN0
RdOK     clrb
         puls  b,x,y,u,pc
RdErr    puls  a,x,y,u,pc      A eats saved B; B is the error

*------------------------------------------------------------
*
* Write
*
* Entry:
* B:X = LSN
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
Write    lda   #QCMD.WR
         bra   Xfer

*------------------------------------------------------------
*
* GetStat / SetStat / Term
*
* No extra status, no allocated buffers, no IRQ. RBF handles the
* usual disk GetStats; these return success.
*
GetStat
SetStat
Term     clrb
         rts

*------------------------------------------------------------
*
* Xfer
*
* Entry:
* A = QCMD.RD or QCMD.WR
* B:X = LSN
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
* A, X, Y restored on success
*
Xfer     pshs  a,b,x,y
         ldx   V.PORT,u
         lda   Q.MAGIC,x
         cmpa  #'Q
         bne   NoDev           virt disk not present
         ldy   4,s             path descriptor
         lda   PD.DRV,y
         sta   Q.DRV,x
         lda   1,s             LSN bits 23-16
         sta   Q.LSN,x
         ldd   2,s             LSN bits 15-0
         std   Q.LSN+1,x
         ldy   PD.BUF,y
         sty   Q.BUF,x
         lda   ,s              command
         sta   Q.CMD,x         QEMU copies 256 bytes here
         ldb   Q.STAT,x
         bne   XferErr
         clrb                  clear carry
         puls  a,b,x,y,pc
XferErr  leas  6,s             drop saved A,B,X,Y; B is Q.STAT
         orcc  #1              keep B as the OS-9 error
         rts
NoDev    leas  6,s
         comb
         ldb   #E$NotRdy
         rts

         emod
eom      equ   *
         end
