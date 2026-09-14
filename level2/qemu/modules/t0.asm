********************************************************************
* T0 - QEMU virt serial device descriptor
********************************************************************

         nam   T0
         ttl   QEMU virt serial descriptor

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Devic+Objct
atrv     set   ReEnt+rev
rev      set   $00

         mod   eom,name,tylg,atrv,mgrnam,drvnam

         fcb   UPDAT.
         fcb   HW.Page
         fdb   T.PORT
         fcb   initsize-*-1
         fcb   DT.SCF          IT.DVC
         fcb   $00             IT.UPC  both cases
         fcb   $01             IT.BSO  BSE,space,BSE
         fcb   $00             IT.DLO  backspace over line
         fcb   $01             IT.EKO  echo
         fcb   $01             IT.ALF  auto line feed on CR
         fcb   $00             IT.NUL
         fcb   $00             IT.PAU  no end-of-page pause
         fcb   24              IT.PAG
         fcb   $08             IT.BSP
         fcb   $18             IT.DEL
         fcb   $0D             IT.EOR
         fcb   $1B             IT.EOF
         fcb   $04             IT.RPR
         fcb   $01             IT.DUP
         fcb   $17             IT.PSC
         fcb   $03             IT.INT
         fcb   $05             IT.QUT
         fcb   $08             IT.BSE
         fcb   $07             IT.OVF
         fcb   $00             IT.PAR
         fcb   $00             IT.BAU
         fdb   name            IT.D2P  echo/output is this device
         fcb   $11             IT.XON
         fcb   $13             IT.XOFF
         fcb   80              IT.COL
         fcb   24              IT.ROW
initsize equ   *

name     fcs   /T0/
mgrnam   fcs   /SCF/
drvnam   fcs   /SCQemu/

         emod
eom      equ   *
         end
