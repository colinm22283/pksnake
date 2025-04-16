.code16

.section .bss

console_buffer = 0xB8000

UP    = 0
DOWN  = 1
LEFT  = 2
RIGHT = 3

init_dst:

fruit_index: .skip 2

snake_dir: .skip 1
snake_len: .skip 2
snake: .skip 1000

.section .rodata, "a"

lose_str: .string "GAME OVER"

init_src:
    .word 80 * 5 + 1
    .byte RIGHT
    .word 3

    .byte 1
    .byte 1
    .byte 1
    .byte 2
    .byte 1
    .byte 3

body_lut:
    .byte '1'
    .byte '2'
    .byte '3'
    .byte '4'
    .byte '5'
    .byte '6'
    .byte '7'
    .byte '8'

.section .entry, "a"

.global entry
entry:
    xor %ax, %ax
    mov %ax, %cs
    mov %ax, %ds
    mov %ax, %ss
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    mov $stack_top, %sp

    mov $0x0003, %ax
	int $0x10

    mov $0x01,   %ah
    mov $0x2000, %cx
    int $0x10

    lea  (random_state), %bx
    movw $0x432F,        (%bx)

restart:
    mov $init_src, %si
    mov $init_dst, %di
    mov $11,       %cx
    rep movsb

    .loop:
        call move_snake
        call clear
        call print_snake

        mov $0x86, %ah
        xor %dx, %dx
        mov $1, %cx
        int $0x15

        jmp .loop

.section .text
clear:
    mov $console_buffer, %ebx
    mov $(80 * 24),      %cx
    mov  %cx,            %ax
    subw (fruit_index),  %ax

    .clear_loop:
        cmp %cx, %ax
        jne .no_fruit
            movw $(0x2403), (%ebx)
            jmp .fruit_end
        .no_fruit:
            movw $(0x2AB0), (%ebx)
        .fruit_end:

        add $2, %bx

        loop .clear_loop

    ret

print_snake:
    mov $0x2002, %dx

    mov (snake_len), %cx
    lea (snake),     %bp

    .print_loop:
        movzx 1(%bp), %ax
        imul  $80,    %ax
        movzx (%bp),  %si
        add   %ax,    %si

        cmp  %si, (fruit_index)
        jne .no_hit
            pusha

            call move_fruit

            lea  (snake_len), %bx
            addw $1,          (%bx)

            popa
        .no_hit:

        shl $1, %si

        mov 0(%bp), %ax # x
        mov 1(%bp), %di # y


        mov $console_buffer, %ebx
        mov %dx, (%ebx, %esi)

        add $2, %bp

        mov $6, %dl
        cmp $2, %cx
        je .skip_body
            mov $8, %dl
        .skip_body:

        cmp $0x20, %dh
        je  .switch_e
            mov $0x20, %dh
        jmp .switch_exit
        .switch_e:
            mov $0x26, %dh
        .switch_exit:

        loop .print_loop

    ret

move_snake:
    mov  (snake_len), %cx
    dec  %cx
    push %cx
    mov $snake,       %di
    movw (%di),       %ax
    movw 1(%di),      %dx
    .check_loop:
        inc %bx
        inc %bx
        
        cmp (%bx),    %ax
        jne .check_bad
            cmp 1(%bx), %dx
            jne .check_bad
                jmp game_end
        .check_bad:

        loop .check_loop


    pop %cx
    mov %cx,          %bx
    shl $1,           %bx
    lea (%bx, %di),        %di
    mov %di,          %si
    dec %si
    dec %si

    std
    rep movsw
    cld
    
    lea (snake_dir), %bx

    mov $1, %ah
    int $0x16
    jz .no_input
        xor %ah, %ah
        int $0x16

        cmp $0x48, %ah
        jne .skip_key_up
            movb $UP, (%bx)
            jmp .no_input
        .skip_key_up:
        cmp $0x50, %ah
        jne .skip_key_down
            movb $DOWN, (%bx)
            jmp .no_input
        .skip_key_down:
        cmp $0x4B, %ah
        jne .skip_key_left
            movb $LEFT, (%bx)
            jmp .no_input
        .skip_key_left:
            movb $RIGHT, (%bx)
    .no_input:

    mov $snake,     %bp

    cmpb $UP, (%bx)
    jne .skip_up
        cmpb $0, 1(%bp)
        jne  .no_up_flip
            movb $24, 1(%bp)
        .no_up_flip:

        subb $1, 1(%bp)
    
        jmp .skip_all
    .skip_up:
    cmpb $DOWN, (%bx)
    jne .skip_down
        cmpb $23, 1(%bp)
        jne  .no_down_flip
            movb $-1, 1(%bp)
        .no_down_flip:

        addb $1, 1(%bp)

        jmp .skip_all
    .skip_down:
    cmpb $LEFT, (%bx)
    jne .skip_left
        cmpb $0, (%bp)
        jne  .no_left_flip
            movb $80, (%bp)
        .no_left_flip:

        subb $1, (%bp)

        jmp .skip_all
    .skip_left:
        cmpb $79, (%bp)
        jne  .no_right_flip
            movb $-1, (%bp)
        .no_right_flip:

        addb $1, (%bp)
        
    .skip_all:

    ret

move_fruit:
    call random_generate

    xor %dx,        %dx
    mov $(80 * 24), %cx
    div %cx
    lea (fruit_index), %bx
    mov %dx,           (%bx)

    ret

game_end:
    mov $(console_buffer + 2 * 80 * 24), %ebx
    mov $lose_str,                   %bp
    mov $9,                          %cx

    .game_end_loop:
        movb (%bp), %al
        inc %bp
        movb %al,  (%ebx)
        inc %ebx
        movb $0x0F, (%ebx)
        inc %ebx

        loop .game_end_loop

    mov $0x86, %ah
    xor %dx, %dx
    mov $(3 * 15), %cx
    int $0x15

    mov $18, %cx
    .game_end_clear:
        dec %ebx
        movb $0, (%ebx)

        loop .game_end_clear

    jmp restart

.section .sig, "a"

.global sig
sig:
    .byte 0x55
    .byte 0xAA

