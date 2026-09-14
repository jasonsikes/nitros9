# CoCo 3 QEMU virt-device boot floppy.
#

RECIPE = coco3_qemu

vpath %.asm $(NITROS9DIR)/level2/qemu/modules

OS9FORMAT_CMD = $(OS9FORMAT_SS35)

KERNEL_TRACK = $(REL) boot_qemu krn

RBF = rbf.mn rbqemu.dr dd.dd d0.dd h0.dd
SCF = scf.mn vtio.dr co3hires.sb joydrv_6552M.sb snddrv_cc3.sb cowin.io \
	term_win80.dt term_win40.dt scqemu.dr t0.dd \
	w.dw w1.dw w2.dw w3.dw w4.dw w5.dw w6.dw w7.dw \
	w8.dw w9.dw w10.dw w11.dw w12.dw w13.dw w14.dw w15.dw

PIPE = pipeman.mn piper.dr pipe.dd
CLOCK = clock_60hz clock2_qemu

BOOTMODS = krnp2 krnp3_perr ioman init sysgo_dd \
	$(RBF) \
	$(SCF) \
	$(PIPE) \
	$(CLOCK)

CMDS_BASE = shell merge grfdrv dir \
	attr copy del deldir display free grep list makdir mdir mfree procs rename tmode help
CMDS_EXTRA += basic09 runb
PORTDEFSDIR =

STARTUP = $(NITROS9DIR)/level2/$(PORT)/startup.qemu

$(MODDIR)/p.dd: p_scbbp.asm | $(MODDIR)
	$(AS) $(AFLAGS) $< $(ASOUT)$@
