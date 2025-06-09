FW_OBJS+=$(OBJ_DIR)/unified.o

$(BIN_DIR)/pksnake: $(FW_OBJS) linker.ld
	mkdir -p $(BIN_DIR)
	$(LD) $(LDFLAGS) $(FW_OBJS) -o $@ -Map=$@.map

include $(MAKE_SCRIPTS)
