********************************************************************
* D0 - QEMU virt floppy device descriptor
********************************************************************

         nam   D0
         ttl   QEMU virt floppy descriptor

         ifp1
         use   defsfile
         use   qemu.d
         endc

tylg     set   Devic+Objct
atrv     set   ReEnt+rev
rev      set   $00

         mod   eom,name,tylg,atrv,mgrnam,drvnam

         fcb   DIR.+SHARE.+PREAD.+PWRIT.+PEXEC.+READ.+WRITE.+EXEC.
         fcb   HW.Page
         fdb   Q.PORT
         fcb   initsize-*-1
         fcb   DT.RBF
         fcb   QD.D0           IT.DRV
         fcb   $00             IT.STP (unused)
         fcb   TYP.HARD        IT.TYP
         fcb   $00             IT.DNS (unused)
         fdb   1               IT.CYL (dummy; size comes from LSN 0)
         fcb   1               IT.SID
         fcb   1               IT.VFY 1 = do not verify
         fdb   18              IT.SCT (dummy)
         fdb   18              IT.T0S
         fcb   1               IT.ILV
         fcb   8               IT.SAS
initsize equ   *

name     fcs   /D0/
mgrnam   fcs   /RBF/
drvnam   fcs   /RBQemu/

         emod
eom      equ   *
         end
