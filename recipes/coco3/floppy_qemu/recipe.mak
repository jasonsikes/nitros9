# CoCo 3 floppy recipe with QEMU virt devices.
#
# Disk contents match recipes/coco3/floppy. The boot disk is the virt
# disk (boot_qemu, RBQemu, Clock2), and the virt console is added to SCF.

RECIPE = coco3_qemu

vpath %.asm $(NITROS9DIR)/level2/qemu/modules

KERNEL_TRACK = $(REL) boot_qemu krn
CLOCK = clock_60hz clock2_qemu
STARTUP = $(NITROS9DIR)/level2/$(PORT)/startup.qemu

MINIMAL ?= 0
MAME ?= 0
ifeq ($(MAME),1)
KEYRPT_DEFAULT = 0
endif
KEYRPT ?= $(KEYRPT_DEFAULT)
CLEAN_EXTRA += startup.keyrpt startup.minimal

ifeq ($(MINIMAL),1)
RECIPE = coco3_qemu_minimal
RBF = rbf.mn rbqemu.dr dd.dd
SCF ?= scf.mn vtio.dr co3hires.sb snddrv_cc3.sb joydrv_joy.sb $(TERM_IO) \
	$(TERM_WIN_DT) scqemu.dr t0.dd
PIPE =
CMDS_BASE = shell grfdrv
SYSDIR =
PORTDEFSDIR =
STARTUP = startup.minimal
ifneq ($(KEYRPT),)
CMDS_BASE += keyrpt
endif
else
RBF = rbf.mn rbqemu.dr dd.dd d0.dd h0.dd
SCF = scf.mn vtio.dr co3hires.sb snddrv_cc3.sb joydrv_joy.sb $(TERM_IO) \
	$(TERM_WIN_DT) w.dw w1.dw w2.dw w3.dw w4.dw w5.dw w6.dw w7.dw \
	w8.dw w9.dw w10.dw w11.dw w12.dw w13.dw w14.dw w15.dw \
	scqemu.dr t0.dd
endif

BOOTMODS = krnp2 ioman init \
	$(RBF) \
	$(SCF) \
	$(PIPE) \
	$(CLOCK) \
	$(BOOTMODS_EXTRA)

ifeq ($(MINIMAL),0)
BASIC09_CMDS = basic09 gfx gfx2 inkey runb syscall
CMDS_EXTRA += $(BASIC09_CMDS)
endif

ifneq ($(KEYRPT),)
ifeq ($(MINIMAL),0)
STARTUP = startup.keyrpt
endif
endif

MAME_BINARY  ?= mame
MAME_MACHINE ?= coco3
MAME_FLAGS   ?= -rompath $(MAME_ROM_PATH) -window -nothrottle -skip_gameinfo -autoboot_delay 5 -autoboot_command "DOS\n" -ext fdc -ext:fdc:wd17xx:0 525qd
