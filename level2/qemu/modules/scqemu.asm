********************************************************************
* SCQemu - QEMU virt serial SCF driver
*
* Driver for /T0.
* One character per Read/Write. Read polls T.STAT; if empty, F$Sleep
* 1 tick so Clock can run and the host can deliver stdin, then retry.
*
* GetStat SS.Ready: function code is in A (SCF). Caller's B gets the
* ready count. SetStat SS.SSig is armed here; a 1-tick VIRQ sends the
* signal when RX is full (copy uses blocking I$Read and never needs
* this; an interactive shell does).
*

         nam   SCQemu
         ttl   QEMU virt SCF serial

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Drivr+Objct
atrv     set   ReEnt+rev
rev      set   $01
edition  set   2
size     equ   ViPkt+ViPktSz   static through the 5-byte VIRQ packet

         mod   eom,name,tylg,atrv,start,size

         fcb   SHARE.+UPDAT.   shareable read/write
name     fcs   /SCQemu/
         fcb   edition

* SCF driver entry table
start    lbra  Init
         lbra  Read
         lbra  Write
         lbra  GetStat
         lbra  SetStat
         lbra  Term

* F$IRQ polling packet. D passed to F$IRQ is ViPkt+Vi.Stat.
IrqPkt   fcb   0               flip
         fcb   Vi.IFlag        mask
         fcb   10              priority

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
* V.PORT already holds $FF10 from the descriptor. Install a 1-tick
* VIRQ so SS.SSig can fire when the host has a character. F$IRQ
* failure skips the VIRQ; either way Init returns success.
*
Init     clra
         sta   SSigPID,u       no SS.SSig armed
         leay  ViPkt+Vi.Stat,u fake VIRQ status register
         tfr   y,d
         leax  IrqPkt,pcr
         leay  IrqSvc,pcr
         os9   F$IRQ
         bcs   InitOk          no poll entry; skip VIRQ
         leay  ViPkt,u
         lda   #$80            repeated VIRQs, IFlag clear
         sta   Vi.Stat,y
         ldd   #1              every tick
         std   Vi.Rst,y
         ldx   #1              install
         os9   F$VIRQ
InitOk   clrb
         rts

*------------------------------------------------------------
*
* Term
*
* Entry:
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
Term     ldx   #0              delete VIRQ
         leay  ViPkt,u
         os9   F$VIRQ
         ldx   #0              remove IRQ poll entry
         os9   F$IRQ
         clrb
         rts

*------------------------------------------------------------
*
* Read
*
* Entry:
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* A = character
* CC = carry set on error
* B = error code
*
Read     ldx   V.PORT,u
         lda   T.STAT,x
         bita  #TRDY.RX
         bne   GotRx           host has a byte
         ldx   #1              one tick; Clock and stdin can run
         os9   F$Sleep
         bcc   Read            retry
         rts                   signal woke us; B is the error
GotRx    lda   T.DATA,x        also clears TRDY.RX
         clrb
         rts

*------------------------------------------------------------
*
* Write
*
* Entry:
* A = character to write
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
* TX never waits; QEMU writes the byte to the chardev here.
*
Write    ldx   V.PORT,u
         sta   T.DATA,x
         clrb
         rts

*------------------------------------------------------------
*
* GetStat
*
* Entry:
* A = function code
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
* SS.Ready: caller's B gets 1 if RX is full, else E$NotRdy.
* SS.EOF always succeeds (a console has no end of file).
* SS.ScSiz returns IT.COL in X and IT.ROW in Y.
*
GetStat  cmpa  #SS.Ready
         beq   GSRdy
         cmpa  #SS.EOF
         beq   GSOk
         cmpa  #SS.ScSiz
         beq   GSSiz
         comb
         ldb   #E$UnkSvc
         rts
GSSiz    ldx   PD.RGS,y        caller's register stack
         clra
         ldb   PD.COL,y
         std   R$X,x           columns
         ldb   PD.ROW,y
         std   R$Y,x           rows
         clrb
         rts
GSRdy    ldx   V.PORT,u
         lda   T.STAT,x
         bita  #TRDY.RX
         bne   GSCnt
         comb
         ldb   #E$NotRdy
         rts
GSCnt    ldx   PD.RGS,y
         ldb   #1              one-byte RX
         stb   R$B,x
GSOk     clrb
         rts

*------------------------------------------------------------
*
* SetStat
*
* Entry:
* A = function code
* Y = path descriptor
* U = address of device memory area
*
* Exit:
* CC = carry set on error
* B = error code
*
* SS.SSig arms a one-shot signal when RX fills. SS.Relea cancels it.
* Any other code returns success.
*
SetStat  cmpa  #SS.SSig
         beq   SetSSig
         cmpa  #SS.Relea
         bne   SSOk            unknown SetStat: success
         clr   SSigPID,u
SSOk     clrb
         rts

SetSSig  tst   SSigPID,u
         beq   ArmSSig
         comb
         ldb   #E$NotRdy       already armed
         rts
ArmSSig  ldx   PD.RGS,y
         lda   PD.CPR,y        process to signal
         ldb   R$X+1,x         signal code
         std   SSigPID,u       PID, then code
         ldx   V.PORT,u
         lda   T.STAT,x
         bita  #TRDY.RX
         beq   SSOk            wait for VIRQ
         bsr   SendSSig        already full; send now
         bra   SSOk

*------------------------------------------------------------
*
* SendSSig
*
* Entry:
* U = address of device memory area
*
* Exit:
* SSigPID cleared (one-shot)
*
SendSSig lda   SSigPID,u
         beq   SendDone        nothing armed
         ldb   SSigSig,u
         clr   SSigPID,u       disarm before F$Send
         os9   F$Send
SendDone rts

*------------------------------------------------------------
*
* IrqSvc
*
* Called from Clock's VIRQ poll. Clear Vi.IFlag, then send SS.SSig
* if it is armed and the host has a character.
*
IrqSvc   lda   ViPkt+Vi.Stat,u
         anda  #~Vi.IFlag      handled
         sta   ViPkt+Vi.Stat,u
         lda   SSigPID,u
         beq   IrqRts          nothing armed
         ldx   V.PORT,u
         lda   T.STAT,x
         bita  #TRDY.RX
         beq   IrqRts          still empty
         bsr   SendSSig
IrqRts   clrb
         rts

         emod
eom      equ   *
         end
