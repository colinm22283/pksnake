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

lose_str: .string "LOSE"

init_src:
    .word 80 * 5 + 1
    .byte RIGHT
    .word 2

    .byte 2
    .byte 1
    .byte 2
    .byte 2

body_lut:
    .byte 201
    .byte 187
    .byte 206
    .byte 200
    .byte 188

random_state: .word 0x432F

.section .entry, "a"

.global entry
entry:
    mov $stack_top, %sp

    mov $0x0003, %ax
	int $0x10

    #mov $0x01,   %ah
    #mov $0x2000, %cx
    #int $0x10

    std

restart:
    mov $(init_src + 10), %si
    mov $(init_dst + 10), %di
    mov $9,       %cx
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

.print_loop_calc:
    push %cx

    movb 0(%bp), %bl # x
    movb 1(%bp), %bh # y

    push %bx

    subb -2(%bp), %bl
    subb -1(%bp), %bh

    not  %bx # not x & y
    
    # negate
    neg  %bh
    neg  %bl

    # store -NOT(y)
    mov  %bh, %cl

    # shr x & y
    shr  $1, %bh
    shr  $1, %bl
    
    add  %cl, %bl
    add  %bh, %bl
    # bl = first block

    pop  %cx
    subb 2(%bp), %cl # x
    subb 3(%bp), %ch # y
    push %cx

    not  %cx # not x & y

    # negate
    neg  %ch
    neg  %cl

    # store -NOT(y)
    mov  %ch, %bh

    # shr x & y
    shr  $1, %ch
    shr  $1, %cl

    add  %cl, %bh
    add  %ch, %bh
    # bh = second block

    add  %bh, %bl

    xor  %bh, %bh

    jmp .print_loop_calc_done

print_snake:
    mov $0x2002, %dx

    mov (snake_len), %cx
    mov $snake,      %bp

    .print_loop:
        movzx 1(%bp), %ax
        imul  $80,    %ax
        movzx (%bp),  %si
        add   %ax,    %si

        mov  $fruit_index, %bx
        cmp  %si, (%bx)
        jne .no_hit
            pusha

            # start move_fruit

            # start random_generate

            mov  (random_state), %ax

            mov %ax, %cx
            shl $7,  %cx
            xor %cx, %ax

            mov %ax, %cx
            shr $9,  %cx
            xor %cx, %ax

            mov %ax, %cx
            shl $8,  %cx
            xor %cx, %ax

            mov %ax, (random_state)

            # end random_generate

            xor %dx,        %dx
            mov $(80 * 24), %cx
            div %cx
            mov %dx,          (%bx)

            # end move_fruit

            mov  $snake_len, %bx
            incw  (%bx)
            shl  $1,         %bx
            movw $0xFFFF,    (snake-2)(%bx)

            popa
        .no_hit:

        shl $1, %si

        mov $console_buffer, %ebx
        mov %dx, (%ebx, %esi)

        inc %bp
        inc %bp

        jmp .print_loop_calc
    .print_loop_calc_done:

        movb (body_lut - 1)(%bx), %dl

        pop %cx
        cmp  $206, %dl
        jne .not_straight
            test %cl, %cl
            jz   .vert
                mov $205, %dl
                jmp .not_straight
            .vert:
                mov $186, %dl
        .not_straight:

        pop %cx

        mov    %dx,   %ax
        mov    $0x20, %ah
        cmp    %ax,   %dx
        mov    $0x26, %dh
        cmovne %ax,   %dx

        loop .print_loop

    ret

move_snake:
    mov  (snake_len), %cx
    dec  %cx
    push %cx
    mov  $snake,      %di
    push %di
    movb (%di),       %al
    movb 1(%di),      %ah
    .check_loop:
        inc  %di
        inc  %di
        
        cmpb (%di),    %al
        jne .check_bad
            cmpb 1(%di), %ah
            jne .check_bad
                mov $(console_buffer + 2 * 80 * 24), %edi
                mov $lose_str,                       %bp
                mov $4,                              %cx

                .game_end_loop:
                    movb (%bp), %al
                    inc %bp
                    movb %al,  (%edi)
                    inc %edi
                    inc %edi

                    loop .game_end_loop

                mov $0x86, %ah
                xor %dx, %dx
                mov $(3 * 15), %cx
                int $0x15

                mov $5,      %cx
                .game_end_clear:
                    movw $0x0F00, (%edi)
                    
                    dec  %edi
                    dec  %edi

                    loop .game_end_clear

                jmp restart
        .check_bad:

        loop .check_loop


    pop %di
    pop %cx
    mov %cx,        %bx
    shl $1,         %bx
    lea (%bx, %di), %di
    mov %di,        %si
    dec %si
    dec %si

    std
    rep movsw
    
    mov $snake_dir, %bx

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

        decb 1(%bp)
    
        jmp .skip_all
    .skip_up:
    cmpb $DOWN, (%bx)
    jne .skip_down
        cmpb $23, 1(%bp)
        jne  .no_down_flip
            movb $-1, 1(%bp)
        .no_down_flip:

        incb 1(%bp)

        jmp .skip_all
    .skip_down:
    cmpb $LEFT, (%bx)
    jne .skip_left
        cmpb $0, (%bp)
        jne  .no_left_flip
            movb $80, (%bp)
        .no_left_flip:

        decb (%bp)

        jmp .skip_all
    .skip_left:
        cmpb $79, (%bp)
        jne  .no_right_flip
            movb $-1, (%bp)
        .no_right_flip:

        incb (%bp)
    .skip_all:

    ret

.section .sig, "a"

.global sig
sig:
    .byte 0x55
    .byte 0xAA

