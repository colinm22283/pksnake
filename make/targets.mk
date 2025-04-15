$(OBJ_DIR)/%.o: $(SOURCE_DIR)/%.s
	mkdir -p $(@D)
	$(ASM) $(ASMFLAGS) $< -o $@
