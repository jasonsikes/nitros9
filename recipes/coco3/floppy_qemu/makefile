LEVEL = 2
include ../coco3.mak

CMDS = $(CMDS_BASE) $(CMDS_EXTRA)

$(MODDIR)/basic09: $(LANGUAGES)/basic09/basic09_$(CPU) | $(MODDIR)
	$(CP) $< $@

$(LANGUAGES)/basic09/basic09_$(CPU):
	$(MAKE) -C $(LANGUAGES)/basic09 basic09_$(CPU)
