.code16

.section .data
debug_prefix: .string "DBG: "

.section .text

.global debug_print
debug_print:
    push %ax
    push %bx
    push %cx
    push %dx
    push %bp
    push %di
    push %si

    push %ax

    mov $0x1300, %ax
    mov $0x000F, %bx
    mov $5,      %cx
    xor %dx,     %dx
    mov $debug_prefix, %bp
    int $0x10

    pop  %bx
    push %bx
    xor  %cx, %cx
    .loop:
        mov  (%bx), %al
        test %al,   %al
        jz   .break_loop

        inc %bx
        inc %cx

        jmp .loop
    .break_loop:

    mov $0x1300, %ax
    mov $0x000F, %bx
    mov $0x0005, %dx
    pop %bp
    int $0x10

    mov $0x86,            %ah
    mov $(1000000 >> 16), %cx
    mov $(1000000),       %dx
    int $0x15

    pop %si
    pop %di
    pop %bp
    pop %dx
    pop %cx
    pop %bx
    pop %ax

    ret
