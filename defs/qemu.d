                    IFNE      QEMU.D-1
QEMU.D              SET       1

********************************************************************
* qemu.d - QEMU virt device definitions for CoCo 3
*
* Map:
*   /D0    virt disk unit 0 (QD.D0), boot floppy (first -drive)
*   /H0    virt disk unit 1 (QD.H0), hard disk
*   /DD    virt disk unit QD.DD (same unit as /D0)
*   /T0    virt serial (SCQemu)
*   /Term  GIME window (vtio), not the virt serial
*
* Ports:
*   Virt disk   $FF30 (PIA1 gap)
*   Virt serial $FF10 (PIA0 gap). Host LF arrives as CR.
*               Mapped to the emulator console (-serial stdio).
*   Virt RTC    $FF50. OS-9 packet (years since 1900).
*               Read R.MAGIC latches a coherent packet.
*
********************************************************************

                    NAM       qemu.d
                    TTL       QEMU virt device definitions


********************************
* SCQemu static storage
*
* Follows SCF manager overhead at V.SCF (scf.d).
*
SSigPID             EQU       V.SCF               SS.SSig process ID (0 = none)
SSigSig             EQU       V.SCF+1             SS.SSig signal code
ViPkt               EQU       V.SCF+2             F$VIRQ packet
ViPktSz             EQU       Vi.PkSz             packet size (os9.d)


********************************
* Path-descriptor copies of IT.COL / IT.ROW
*
* scf.d defines those only in the device descriptor (IT.*).
*
PD.COL              EQU       PD.OPT+(IT.COL-IT.DVC)
PD.ROW              EQU       PD.OPT+(IT.ROW-IT.DVC)


********************************
* Virt disk $FF30
*
* TYP.HARD (rbf.d) in IT.TYP bit 7 so RBF will not ask for step rate,
* density, or disk-change. The image is still a 256-byte-sector RBF
* volume (a NitrOS-9 .dsk); dummy IT.CYL/IT.SCT, size from LSN 0.
*
Q.MAGIC             EQU       0                   read 'Q'
Q.VER               EQU       1
Q.CMD               EQU       2                   1=read 2=write
Q.STAT              EQU       3                   0=ok, else OS-9 error
Q.DRV               EQU       4
Q.LSN               EQU       5                   3 bytes, big-endian
Q.BUF               EQU       8                   2-byte CPU address
QCMD.RD             EQU       1
QCMD.WR             EQU       2
QD.D0               EQU       0
QD.DD               EQU       QD.D0               /DD unit
QD.H0               EQU       1
Q.NDRV              EQU       2
Q.PORT              EQU       $FF30


********************************
* Virt console $FF10
*
T.MAGIC             EQU       0                   read 'Q'
T.VER               EQU       1
T.DATA              EQU       2                   write TX, read RX
T.STAT              EQU       3                   bit 0 = RX ready
TRDY.RX             EQU       $01
T.PORT              EQU       $FF10


********************************
* Virt RTC $FF50
*
R.MAGIC             EQU       0                   read 'Q'
R.VER               EQU       1
R.YEAR              EQU       2
R.MONTH             EQU       3
R.DAY               EQU       4
R.HOUR              EQU       5
R.MIN               EQU       6
R.SEC               EQU       7
R.PORT              EQU       $FF50

                    ENDC
