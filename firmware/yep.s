.code16

.section .bss

.global board
board: .skip 80 * 24

.global cur_x
cur_x: .skip 2
.global cur_y
cur_y: .skip 2

.section .data

boom_str: .string ""
win_str:  .string ""

blank = 0
safe  = 10
csafe = 11
cmine = 12

mine_count = 25

.section .entry, "a"

.global entry
entry:
    mov $0x0003, %ax
	int $0x10

    movw $1, (random_state)

.global restart
restart:
    mov $stack_top, %sp
    mov $cur_x, %si
    mov $cur_y, %di
    mov $board, %bp

    pusha

    mov %bp,        %bx
    mov $(80 * 24), %cx
    .ib_loop:
        movb $csafe, (%bx)
        inc  %bx

        loop .ib_loop

    inc %cx
    mov %cx, (%si)
    mov %cx, (%di)
    
    mov $mine_count, %cx
    .ib_mine_loop:
        push  %cx

        mov   $22, %cx
        call .ib_gen_num
        push  %dx

        mov   $78, %cl
        call .ib_gen_num
        mov   %dx, %cx

        pop   %ax
        mov   $80, %bl
        mul   %bl
        mov   %ax, %si
        add   %cx, %si

        movb  $cmine, (%bp, %si)

        pop   %cx

        loop  .ib_mine_loop

    popa

    .loop:
        push %si
        push %di

        mov $0x02, %ah
        xor %bh,   %bh
        xor %dx,   %dx
        int $0x10

        mov $80,   %ah
        mov (%di), %al
        mul %ah
        add (%si), %ax

        mov %bp, %bx
        xor %cx, %cx
        .bp_loop:
            pusha

            mov  $0x000F, %dx

            cmp  %ax, %cx
            jne  ..not_cur
                mov $0xF0, %dl
            ..not_cur:

            movb (%bx), %al
            test %al,   %al
            jz  ..bp_blank 
            cmp  $safe, %al
            ja   ..bp_uncovered
                add $'0', %al
                jmp ..bp_skip
            ..bp_blank:
                mov $' ', %al
                jmp ..bp_skip
            ..bp_uncovered:
                mov $'#', %al
            ..bp_skip:

            mov $0x09,   %ah
            mov %dx,     %bx
            mov $1,      %cx
            int $0x10

            mov $0x03,   %ah
            xor %bh,     %bh
            int $0x10
            
            inc %dl
            cmp $80, %dl
            jne ..bp_no_cur_reset
                xor %dl, %dl
                add $1,  %dh
            ..bp_no_cur_reset:

            mov $0x02, %ah
            xor %bh,   %bh
            int $0x10

            popa

            inc %bx
            inc %cx

            cmp $(80 * 24), %cx
            jb  .bp_loop
        
        # do input stuff
        xor  %ah, %ah
        int  $0x16

        pop %di
        pop %si

        mov  (%si), %bx
        mov  (%di), %cx

        cmp   $0x48, %ah
        je   .in_up
        cmp  $0x50, %ah
        je   .in_down
        cmp  $0x4B, %ah
        je  .in_left
        cmp  $0x4D, %ah
        je  .in_right
        .in_enter:
            call uncover_cell

            jmp .input_skip_no_write
        .in_up:
            cmp $1, %cx
            je  .input_skip

            dec %cx

            jmp .input_skip
        .in_down:
            cmp $22, %cx
            je  .input_skip

            inc %cx
            
            jmp .input_skip
        .in_left:
            cmp $1, %bx
            je  .input_skip

            dec %bx

            jmp .input_skip
        .in_right:
            cmp $78, %bx
            je  .input_skip
            
            inc %bx

        .input_skip:
        
        mov  %bx, (%si)
        mov  %cx, (%di)

        .input_skip_no_write:

        mov  $(board + 80 + 1), %bx
        mov  $22,               %cx
        .cw_loop:
            push %cx

            mov $78, %cx
            .cw_loop_inner:
                cmpb $csafe, (%bx)
                jne  .cw_not_covered
                    pop %cx
                    jmp .loop
                .cw_not_covered:

                inc %bx

                loop .cw_loop_inner
            
            pop %cx

            add $2, %bx

            loop .cw_loop

        mov  $win_str, %bp
        mov  $0x1F,    %bl
        jmp print_end

.section .text

    .ib_gen_num:
        call random_generate
        xor  %dx, %dx
        div  %cx
        inc  %dx
        
        ret

.global uncover_cell
uncover_cell:
    mov (%si), %bx
    mov (%di), %ax
    
    test %ax, %ax
    jz  .uc_ret
    test %bx, %bx
    jz  .uc_ret
    cmp $79, %bx
    je .uc_ret
    cmp $24, %ax
    jne .uc_no_ret

    .uc_ret:
        ret
    .uc_no_ret:

    mov $80, %cl
    mul %cl
    add %ax, %bx

    add %bp, %bx
    mov (%bx),  %al

    cmp $csafe, %al
    jb  ..uc_ret
        cmp $cmine, %al
        jne ..uc_not_mine    
            mov $boom_str, %bp
            mov $0x4f,     %bl
            jmp print_end
        ..uc_not_mine:
        cmp $csafe, %al
        jne ..uc_not_safe
            # bx is board cur addr
            lea (%bx), %bx
            
            xor %dx, %dx
            
            mov  $.uc_check_mine, %ax
            mov  -81(%bx),   %cx
            call *%ax
            mov  -79(%bx),   %cl
            mov  -1(%bx),    %ch
            call *%ax
            mov  1(%bx),     %cl
            mov  79(%bx),    %ch
            call *%ax
            mov  80(%bx),    %cx
            call *%ax
            
            mov %dl, (%bx)

            test %dl, %dl
            jnz  ...uc_not_zero_mines
                mov $-1, %ax
                xor %bx, %bx
                mov $1,  %cx

                push %ax
                push %bx
                push %cx
                push %ax

                push %ax
                push %cx
                push %bx

                push %ax
                push %bx
                push %cx
                push %cx

                mov  $.uc_zero_recur, %cx
                
                pop %ax
                call *%cx
                call *%cx
                call *%cx

                pop %ax
                call *%cx
                call *%cx

                pop %ax
                call *%cx
                call *%cx
                call *%cx
            ...uc_not_zero_mines:
        ..uc_not_safe:
    ..uc_ret:

    ret

    .uc_check_mine:
        cmp $cmine, %ch
        jne ..uc_skip_first
            inc %dx
        ..uc_skip_first:
        cmp $cmine, %cl
        jne ..uc_skip_second
            inc %dx
        ..uc_skip_second:

        ret

    .uc_zero_recur:
        pop  %dx
        pop  %bx
        push %dx

        push %cx

        mov (%si), %cx
        mov (%di), %dx

        pusha
        
        add  %ax, %cx
        add  %bx, %dx
        mov  %cx,     (%si)
        mov  %dx,     (%di)
        call uncover_cell

        popa

        mov %cx, (%si)
        mov %dx, (%di)

        pop %cx

        ret

.global print_end
print_end:
    mov $0x1300,   %ax
    xor %bh,       %bh
    #mov $0x004F,   %bx
    mov $1,        %cx
    xor %dx,       %dx
    #int $0x10


    mov $0x86,     %ah
    mov $46,       %cx
    xor %dx,       %dx
    #int $0x15

    jmp restart

.section .sig, "a"

.global sig
sig:
    .byte 0x55
    .byte 0xAA

