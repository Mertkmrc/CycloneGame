Start:
LDR R0, =0xFF200000 // Address of LEDs
LDR R1, =0xFFFEC600 // R1 points to Timer
LDR R3, =0xFF200050 // Address of Push Buttons
LDR R5, =0xFF200020 // Address of 7 Segment Display
LDR R9, =speed_Check // Pointer for SPEED0-3
LDR R7, [R9] // Load the 7 segment display values for speed check, SPEE 
LDR R9, [R9, #4] // Load the second value D0-3 by updating the pointer
STR R7, [R5, #16] // Display SPEE we got from speed_Check to 7 segment in left 4
digits
STR R9, [R5] // Display D0-3 in right 4 digits
Input:
LDR R7, [R3,#0xC] // Load the status register of timer
LDR R9, =speed_num // Load pointer of level of the speeds
CMP R7, #0 //Check for if any button pushed or not
BEQ Input
CMP R7, #2 // Check for button 1 pushed or not
ADDEQ R9, R9, #4 // If yes, update the pointer for getting second speed value
CMP R7, #4 // Check for button 2 pushed or not
ADDEQ R9, R9, #8 // If yes, update the pointer for getting third speed value
CMP R7, #8 // Check for button 3 pushed or not
ADDEQ R9, R9, #12 // If yes, update the pointer for getting fourth speed value
STR R7, [R3, #0xC] // Reset edge-capture register
LDR R2, [R9] // Get the shift speed value of pointer shows
STR R2, [R1] // Load the value to timer
MOV R2, #0b011 // Control word that sets Enable and Auto as 1
STR R2, [R1, #8] // Load the control word to control register
MOV R2, #1 // 1 for initialize the LED0 is on
MOV R8, #0 // Score of the Player A
MOV R9, #0 // Score of the Player B
LDR R10, =SegmentCode
MOV R11, R10 // Score’s pointer of Player A for 7-segment display

MOV R12, R10 // Score’s pointer of Player B for 7-segment display
BL DISPLAY
Mainloop: STR R2, [R0] // Update the LEDs
Inner_loop: LDR R4, [R1, #0xC] // Check the status register
CMP R4, #1 // if 1, go for the next LED.
BNE Inner_loop
STR R4, [R1, #0xC] // Reset status register
LSL R2, R2, #1 // Shift to light up the next LED
CMP R2, #512 // Check if LED8 was on the previous round. If so clearing the edge
capture register
BLEQ Push_Button_Clear
CMP R2, #1024 // Check if LED9 was light up previous round
MOVEQ R2, #1 // If so return back to LED0
BLEQ KEY_CHECK
B Mainloop
KEY_CHECK:
PUSH {LR}
LDR R7, [R3,#0xC] // Load edge-capture register
CMP R7, #1 // Only Player B scored
BLEQ SCORE_B
CMP R7, #8 // Only Player A scored
BLEQ SCORE_A
CMP R7, #9 // Both Player A and Player B scored
BLEQ SCORE_B
BLEQ SCORE_A
STR R7, [R3, #0xC] // Reset edge-capture register
BL DISPLAY
CMP R8, #9 // Check if Player A won
MOVEQ R6, #0 // Counter register to count the # of winner screen cycles
BLEQ Set_Timer
BEQ WINNER_A
CMP R9, #9 // Check if Player B won
MOVEQ R6, #0 // Counter register to count the # of winner screen cycles
BLEQ Set_Timer
BEQ WINNER_B
POP {PC}

Push_Button_Clear:
LDR R7, [R3, #0xC] // Read the edge-capture register
STR R7, [R3, #0xC] // Clear edge-capture register
BX LR
SCORE_A:
ADD R8, R8, #1 // Increment the score
ADD R11, R10, R8, LSL #2 // Update the pointer for 7-segment display
BX LR
SCORE_B:
ADD R9, R9, #1 // Increment the score
ADD R12, R10, R9, LSL #2 // Update the pointer for 7-segment display
BX LR
noldu
WINNER_A:
LDR R4, =player // Pointer for displaying PLAYER
LDR R7, [R4] // Load hex values of PLAY
LDR R4, [R4, #4] // Update pointer and load ER
STR R7, [R5, #16] // Display "PLAY" on left 4 digits
ORR R4, R4, #0x77 // Concatenate the ER with A
STR R4, [R5] // Display “ER A” on right 4 digits
CMP R9, R8 // Check if they tied in the score
BLEQ DELAY
BEQ WINNER_B // If so wait then show PLAYER B on 7 segment as well
B Done
WINNER_B:
LDR R4, =player // Pointer for displaying PLAYER
LDR R7, [R4] // Load hex values of PLAY
LDR R4, [R4, #4] // Update pointer and load ER
STR R7, [R5, #16] // Display "PLAY" on left 4 digits
ORR R4, R4, #0x7C //Concatenate the ER with B
STR R4, [R5] // Display “ER B” on right 4 digits
B Done
Done:
ADD R6, R6, #1 // Increment the winner loop counter
BL DELAY
BL DISPLAY
BL DELAY

CMP R6, #8 // If 8 cycles is complete, check if there is an input
BLEQ Push_Button_Clear
BLGT Restart_Check
CMP R8, #9 // Check who the winner was looping to display the player
BEQ WINNER_A
CMP R9, #9
BEQ WINNER_B
B Done
DELAY:
LDR R4, [R1, #0xC] // Check status register
CMP R4, #1 // If 1, 1 second is completed
BNE DELAY
STR R4, [R1, #0xC] // Reset status register
BX LR
Set_Timer:
LDR R2, =100000000 // Load value corresponds to 0.5 second
STR R2, [R1] // Load the value to timer
MOV R2, #0b011 // Control word
STR R2, [R1, #8] // Load the control word to control register
BX LR
DISPLAY:
PUSH {R8, R9}
MOV R7, #0 // Load 0 to clear left 4 digits of 7 segment
STR R7, [R5, #16] // Clear left 4 digits of 7 segment
LDR R8, [R12] // Get score of PlayerA
LDR R9, [R11] // Get score of PlayerB
ADD R7, R8, R9, LSL #24 // Write scores into one words
STR R7, [R5] // Store Score A X X Score B to 7 segment
POP {R8, R9}
BX LR
Restart_Check:
LDR R7, [R3,#0xC] // Load edge-capture register
CMP R7, #0 // Check if there is any input
STR R7, [R3, #0xC] // Reset edge-capture register
BNE Start // If there is an input restart the game
BX LR

end: B end

SegmentCode: //Number representations for 7 segment
.word 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77
player:
.word 0x7338776e, 0x79500000 // PLAY, ER
speed_Check:
.word 0x6d737979, 0x5e3f404f // SPEE, D0-3
speed_num:
.word 0xBEBC200, 0x5F5E100, 0x2FAF080, 0x17D7840 // Hex values of the speeds: 1, 0.5,
0.25, and 0.125
.end
