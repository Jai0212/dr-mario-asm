################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Ethan Liu, 1010290338
# Student 2: Jai Joshi, 1009881013
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
# The address of the initial position of the capsule
CAPSULE_INIT_POS:
    .word 0x10008334  # ADDR_DSPL + 820

RED:
    .word 0xff0000
BLUE:
    .word 0x0000ff
YELLOW:
    .word 0xffff00
BLACK:
    .word 0x000000
GRAY:
    .word 0x808080
    
VIRUS_RED:
    .word 0xff7f7f
VIRUS_BLUE:
    .word 0xadd8e6
VIRUS_YELLOW:
    .word 0xffffe0
    
HEIGHT:
    .word 0x000018
WIDTH:
    .word 0x000011
START:
    .word 0x00000614
    
# game states
GAME_OVER:  # game over
    .word 0
READY:  # get the next capsule
    .word 1
ENTERING:  # move the capsule into the bottle
    .word 2
FALLING:  # player can control the capsule
    .word 3
    

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    addi $s6, $zero, 1  # s6 repr the game state, 1 is ready state
    addi $s7, $zero, 0  # fps counter
    
    j draw_bottle  # will jump to init_capsules

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed

    # draw the upcomming capsules
    addi $t0, $sp, -16
    lw $t1, CAPSULE_INIT_POS
    addi $t1, $t1, 56
    li $t2, 0  # loop counter
    jal draw_capsule_queue

    # handle game states
    lw $t1, READY
    beq $s6, $t1, handle_ready_state
    
    # 60 fps
    li $v0, 32
    li $a0, 16
    syscall  # sleeps for ~1/60s
    
    # handle fps counter, # s7 == 60 => update capsule position
    addi $s7, $s7, 1
    bne $s7, 60, skip_gravity 
    addi $s7, $zero, 0
    # TODO move capsule down
    # TODO remove print
    li $v0, 1
    li $a0, 1
    syscall
    
handle_ready_state:
    lw $t0, CAPSULE_INIT_POS
    addi $t1, $sp, -8  # get a player controlled capsule
    lw $t2, 0($t1)
    sw $t2, 0($t0)
    addi $t1, $t1, 4
    lw $t2, 0($t1)
    sw $t2, 256($t0)
    
    lw $s6, ENTERING
    j game_loop
    
handle_entering_state:
    # animation for capsule to move into bottle
    lw $t0, CAPSULE_INIT_POS
    
    li $v0, 32
    li $a0, 1000
    syscall
    
    addi $s7, $zero, 0  # reset fps counter to avoid sudden changes due to previous fps values
    j game_loop
    
skip_gravity:
    # TODO remove print
    li $v0, 1
    li $a0, 0
    syscall
    j game_loop
    
draw_bottle:
    li $t2, 0x808080 # color of bottle
    lw $t3, ADDR_DSPL # initial address
    
    # t0: repr starting pos to draw pixel
    # a0: repr how many pixels to draw
    # t1: repr the counter
    
    # increment the column first, then offset the row for the starting position
    # the game board size is 17 * 24, and the bottle is 3 squares from the border
    addi $t0, $t3, 1024
    addi $t0, $t0, 20
    li $t1, 0
    li $a0, 6
    jal draw_line_row
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 64
    li $t1, 0
    li $a0, 6
    jal draw_line_row
    
    addi $t0, $t3, 7424
    addi $t0, $t0, 20
    li $t1, 0
    li $a0, 17
    jal draw_line_row
    
    addi $t0, $t3, 512
    addi $t0, $t0, 44
    li $t1, 0
    li $a0, 3
    jal draw_line_column

    addi $t0, $t3, 512
    addi $t0, $t0, 60
    li $t1, 0
    li $a0, 3
    jal draw_line_column
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 16
    li $t1, 0
    li $a0, 26
    jal draw_line_column
    
    addi $t0, $t3, 1024
    addi $t0, $t0, 88
    li $t1, 0
    li $a0, 26
    jal draw_line_column
    
    j init_capsules
    
draw_line_row:
    beq $t1, $a0, back_to_draw_bottle
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j draw_line_row
    
draw_line_column:
    beq $t1, $a0, back_to_draw_bottle
    sw $t2, 0($t0)
    addi $t0, $t0, 256
    addi $t1, $t1, 1
    j draw_line_column
    
back_to_draw_bottle: jr $ra

finish_keyboard_input:
    
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	
	# 4. Sleep
	li 		$v0, 32
	li 		$a0, 1
	syscall

    # 5. Go back to Step 1
    j game_loop

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x57, respond_to_W     # Check if the key w was pressed
    beq $a0, 0x41, respond_to_A     # Check if the key a was pressed
    beq $a0, 0x53, respond_to_S     # Check if the key s was pressed
    beq $a0, 0x44, respond_to_D     # Check if the key d was pressed

    # li $v0, 1                       # ask system to print $a0
    # syscall

    j finish_keyboard_input

respond_to_Q:
    li $v0, 10                      # Quit gracefully
	syscall
	
	b finish_keyboard_input

# rotate capsule by 90 degrees clockwise 
respond_to_W:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2
    add $a2, $zero, $s2 # initialize number of times rotated
    
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, BLACK       # BLACK
    add $t2, $zero, $t2 # store BLACK
    
    beq $a2, 0, respond_to_W_top_to_right       # original state
    beq $a2, 1, respond_to_W_right_to_bottom    # 1 rotation
    beq $a2, 2, respond_to_W_bottom_to_left     # 2 rotations
    beq $a2, 3, respond_to_W_left_to_top        # 3 rotations

respond_to_W_top_to_right:
    lw $t3, 4($a1)      # store colour of right address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    
    sw $t0, 4($a1)      # update memory to store updated coordinate 2
    
    addi $a0, $a1, 4    # new pixel right/bottom location
    
    add $s0, $zero, $a1 # new pixel saved in s0
    add $s1, $zero, $a0 # new pixel saved in s1
    
    j respond_to_W_end

respond_to_W_right_to_bottom:
    lw $t3, 256($a0)    # store colour of bottom address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t1, 256($a0)    # update memory to store updated coordinate 2
    
    addi $a1, $a0, 256  # new pixel right/bottom location
    
    add $s0, $zero, $a0 # new pixel saved in s0
    add $s1, $zero, $a1 # new pixel saved in s1
    
    j respond_to_W_end

respond_to_W_bottom_to_left:
    lw $t3, -4($a0)      # store colour of right address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t1, -4($a0)     # update memory to store updated coordinate 2
    
    addi $a1, $a0, -4   # new pixel right/bottom location
    
    add $s0, $zero, $a1 # new pixel saved in s0
    add $s1, $zero, $a0 # new pixel saved in s1
    
    j respond_to_W_end

respond_to_W_left_to_top:
    lw $t3, -256($a1)   # store colour of bottom address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    
    sw $t0, -256($a1)   # update memory to store updated coordinate 2
    
    addi $a0, $a1, -256 # new pixel right/bottom location
    
    add $s0, $zero, $a0 # new pixel saved in s0
    add $s1, $zero, $a1 # new pixel saved in s1
    
    j respond_to_W_end
    
respond_to_W_end:
    # update number of rotations
    addi $s2, $s2, 1    # increase number of rotations by 1
 
    blt $s2, 4, finish_keyboard_input   # if number of new rotations is less than 4, return
    
    add $s2, $zero, $zero   # make number of rotations 0 again if exceeds 4 (back to original state_
    
    j finish_keyboard_input


# move capsule to the left
respond_to_A:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2
    
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, BLACK       # BLACK
    add $t2, $zero, $t2 # store BLACK

respond_to_A_vertical_horizontal:
    lw $t3, -4($a0)      # store colour of left address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t0, -4($a0)     # update memory to store updated coordinate 1
    sw $t1, -4($a1)     # update memory to store updated coordinate 2
    
    addi $a0, $a0, -4  # new pixel left/top location
    addi $a1, $a1, -4  # new pixel right/bottom location
    
    add $s0, $zero, $a0 # new left/top pixel saved in s0
    add $s1, $zero, $a1 # new right/bottom pixel saved in s1
    
    j finish_keyboard_input
    

# move capsule to the right
respond_to_D:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2
    
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, BLACK       # BLACK
    add $t2, $zero, $t2 # store BLACK

respond_to_D_vertical_horizontal:
    lw $t3, 4($a1)      # store colour of right address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t0, 4($a0)     # update memory to store updated coordinate 1
    sw $t1, 4($a1)     # update memory to store updated coordinate 2
    
    addi $a0, $a0, 4  # new pixel left/top location
    addi $a1, $a1, 4  # new pixel right/bottom location
    
    add $s0, $zero, $a0 # new left/top pixel saved in s0
    add $s1, $zero, $a1 # new right/bottom pixel saved in s1
    
    j finish_keyboard_input


# move capsule all the way to the bottom
respond_to_S:
    addi $a2, $zero, 1  # send 1 to move_down in $a2
    
respond_to_S_while:
    j move_down # will terminate inside move_down


# move down capsule by 1
# returns 1 if successful move down, 0 otherwise
# return value in $v0
move_down:
    add $a0, $zero, $s0 # initialize coordinate 1
    add $a1, $zero, $s1 # initialize coordinate 2
    
    lw $t0, 0($a0)      # coordinate 1 in matrix
    lw $t1, 0($a1)      # coordinate 2 in matrix
    lw $t2, BLACK       # BLACK
    add $t2, $zero, $t2 # store BLACK
    
    addi $t6, $zero, 1  # store 1
    lw $t7, 0($a2)      # check if function called by respond_to_S, 1 if yes, 0 if not
    
    add $v0, $zero, $zero   # initialize return value of 0 
    
    addi $t3, $a0, 4    # go to next address horizontally
    beq $t3, $a1, move_down_horizontal  # if capsule is horizontal
    
move_down_vertical:
    lw $t3, 256($a1)    # store colour of bottom address
    
    bne $t3, $t2, finish_keyboard_input # if not black, return 0

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t0, 256($a0)    # update memory to store updated coordinate 1
    sw $t1, 256($a1)    # update memory to store updated coordinate 2
    
    addi $a0, $a0, 256  # new pixel top location
    addi $a1, $a1, 256  # new pixel bottom location
    
    add $s0, $zero, $a0 # new top pixel saved in s0
    add $s1, $zero, $a1 # new bottom pixel saved in s1
    
    addi $v0, $zero, 1  # successful move down vertically, return 1
    
    beq $t6, $t7, respond_to_S_while    # if function called by respond_to_S and we were able to move down, call it again
    
    j finish_keyboard_input
    
move_down_horizontal:
    lw $t3, 256($a0)    # store colour of bottom left address
    lw $t4, 256($a1)    # store colour of bottom right address
    
    bne $t3, $t2, finish_keyboard_input # if not black (bottom left), return 0
    bne $t4, $t2, finish_keyboard_input # if not black (bottom right), return 0

    sw $t2, 0($a0)      # make pixel where capsule was black
    sw $t2, 0($a1)      # make pixel where capsule was black
    
    sw $t0, 256($a0)    # update memory to store updated coordinate 1
    sw $t1, 256($a1)    # update memory to store updated coordinate 2
    
    addi $a0, $a0, 256  # new pixel left location
    addi $a1, $a1, 256  # new pixel right location
    
    add $s0, $zero, $a0 # new left pixel saved in s0
    add $s1, $zero, $a1 # new right pixel saved in s1
    
    addi $v0, $zero, 1  # successful move down vertically, return 1
    
    beq $t6, $t7, respond_to_S_while    # if function called by respond_to_S and we were able to move down, call it again
    
    j finish_keyboard_input
    
    
# This initializes an array of capsules on the stack, where 4 bytes corresponds to a color and 8 bytes represents a capsule.
# Imaging this as a queue data structure. The first element is the capsule that the player is controlling, the rest are
# the upcommign capsules. Note that stack is "backwards".   
init_capsules:
    # $a2 is the address to store the capsule 
    addi $a2, $sp, -8
    jal generate_capsule  
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    addi $a2, $a2, -8
    jal generate_capsule
    j game_loop

# Param: initialize $a2 at stack for location
generate_capsule:
    j which_capsule
    
# decides which capsule to display next
# 0: red-red
# 1: yellow-yellow
# 2: blue-blue
# 3: red-blue
# 4: red-yellow
# 5: blue-yellow
which_capsule:
    # generate random number between 0 and 5 (inclusive) to decide which capsule to display next
    # result stored in $a0
    li $v0 , 42
    li $a0 , 0
    li $a1 , 6
    syscall
    
    # invoke specific colour function based on number generated
    beq $a0, 0, which_capsule_0
    beq $a0, 1, which_capsule_1
    beq $a0, 2, which_capsule_2
    beq $a0, 3, which_capsule_3
    beq $a0, 4, which_capsule_4
    beq $a0, 5, which_capsule_5

which_capsule_0:
    # red-red
    lw $t0, RED
    add $t0, $zero, $t0  # dereference addr for color
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra

which_capsule_1:
    # yellow-yellow
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra

which_capsule_2:
    # blue-blue
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    sw $t0, 4($a2)
    jr $ra

which_capsule_3:
    # red-blue
    lw $t0, RED
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra

which_capsule_4:
    # red-yellow
    lw $t0, RED
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra
    
which_capsule_5:
    # blue-yellow
    lw $t0, BLUE
    add $t0, $zero, $t0
    sw $t0, 0($a2)
    lw $t0, YELLOW
    add $t0, $zero, $t0
    sw $t0, 4($a2)
    jr $ra
    
# draws the capsule at the bottle neck 
# TODO the function jumping may be changed later when generation state management is implemented
draw_capsule:
    # lw $t0, CAPSULE_INIT_POS
    # sw $v0, 0($t0)
    # sw $v1, 256($t0)
    jr $ra
    
# t0 represents to the stack address of the capsule
# t1 represents the position on the display to draw the capsule
# t2 is a loop counter
draw_capsule_queue:
    # drawing the capsule
    lw $t3, 0($t0)  # retrieve color from stack
    sw $t3, 0($t1)  # drawing on the display
    lw $t3, 4($t0)
    sw $t3, 256($t1)
    addi $t0, $t0, -8
    
    addi $t1, $t1, 8
    addi $t2, $t2, 1
    bne $t2, 5, draw_capsule_queue
    jr $ra
    
# generates and displays random viruses across the map
generate_virus:
    addi $t7, $zero, 4      # store 4
    addi $t6, $zero, 256    # store 256

generate_virus_red:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

    lw $t0, 0($a0)  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    la $t5, START       # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    lw $t3, VIRUS_RED   # VIRUS_RED
    add $t3, $zero, $t3 # store VIRUS_RED

    sw $t3, 0($t5)      # store VIRUS_RED at virus location

generate_virus_blue:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

    lw $t0, 0($a0)  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    la $t5, START       # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    lw $t3, VIRUS_BLUE  # VIRUS_BLUE
    add $t3, $zero, $t3 # store VIRUS_BLUE

    sw $t3, 0($t5)      # store VIRUS_BLUE at virus location

generate_virus_yellow:
    # generate random number between 0 and 17 (exclusive) to decide which column to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 17
    syscall

    lw $t0, 0($a0)  # random column
    mult $t0, $t7
    mflo $t0        # multiply by 4 and store result

    # generate random number between 12 and 24 (exclusive)to decide which row to display virus on
    # result stored in $a0
    li $v0, 42
    li $a0, 0
    li $a1, 12
    syscall

    addi $t1, $a0, 12   # random row
    mult $t1, $t6
    mflo $t1            # multiply by 256 and store result

    lw $t5, START       # store START address
    add $t5, $t5, $t0   # add columns to START
    add $t5, $t5, $t1   # add rows to START + columns, final address to store virus

    lw $t3, VIRUS_YELLOW    # VIRUS_YELLOW
    add $t3, $zero, $t3     # store VIRUS_YELLOW

    sw $t3, 0($t5)      # store VIRUS_YELLOW at virus location


# in case of horizontal or vertical matching, remove adjacent blocks
check_pattern:
    lw   $t5, START     # Load base address of matrix into $t5
    li   $t6, 24        # Height of matrix (number of rows)
    li   $t7, 17        # Width of matrix (number of columns)
    li   $t1, 0         # Row index (i)

check_pattern_row_loop:
    li   $t2, 0         # Column index (j)

check_pattern_col_loop:
    mul  $t3, $t1, 68   # Row offset: i * (17 * 4)
    mul  $t4, $t2, 4    # Column offset: j * 4
    add  $t8, $t5, $t3  # Base address + row offset
    add  $t8, $t8, $t4  # Add column offset

    lw   $t9, 0($t8)    # Load matrix[i][j] into $t9

    addi $t2, $t2, 1    # j++
    blt  $t2, $t7, check_pattern_col_loop  # If j < 17, repeat

    addi $t1, $t1, 1    # i++
    blt  $t1, $t6, check_pattern_row_loop  # If i < 24, repeat
    
