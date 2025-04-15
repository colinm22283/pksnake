OUTPUT_FORMAT("binary");
ENTRY(entry);

SECTIONS {
    . = 0x0500;
    .stack (NOLOAD) : {
        stack_base = .;
        . += 0x07C00 - 0x00500 - 16;
        . = ALIGN(16);
        stack_top = .;
    }

    . = 0x7C00;

    .entry 0x7C00 : AT(0x000) {
        *(.entry*);
        *(.text*);
        *(.rodata*);
        *(.data*);
    }

    .sig 0x7DFE : AT(0x01FE) {
        *(.sig*); 
    }

    . = 0x7E00;

    .data (NOLOAD) : {
        *(.bss*);
    }
}
