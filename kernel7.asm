format binary as 'img'

org $0000
mov sp,$1000

; memory addresses of BASE
BASE = $3F000000
mov r0,BASE

GPIO_OFFSET   = $200000

; game object dimensions
BALL_WIDTH    = 24
PADDLE_WIDTH  = 20
PADDLE_HEIGHT = 120

; initialise the frame buffer
bl FB_Init
;r0 now contains address of screen
;SCREEN_X and BITS_PER_PIXEL are global constants populated by FB_Init

and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

; back-up a copy of the screen address + channel number into r7
mov r7,r0

; TODO 
; add ball collision to paddles
; player input

; data
align 4
; ball properties
ball_x: 
  dw 250
ball_y: 
  dw 200
ball_direction: 
  dw 0 ; 0: SE, 1: NE, 2: NW, 3: SW
; paddle properties
paddle_player_x:
  dw 20
paddle_player_y:
  dw 180
paddle_ai_x:
  dw 600
paddle_ai_y:
  dw 180

; the main game loop, updates the screen on every iteration
refresh_screen:
  ; erase screen objects
  push {r0-r12}
    mov r0, #0
    bl draw_ball
  pop {r0-r12}

  push {r0-r12}
    mov r0, #0
    bl draw_paddle_player
  pop {r0-r12}

  push {r0-r12}
    mov r0, #0
    bl draw_paddle_ai
  pop {r0-r12}

  ; update game state
  push {r0-r12}
    bl update_state
  pop {r0-r12}

  ; draw screen objects with updated positions
  push {r0-r12}
    mov r0, #1
    bl draw_ball
  pop {r0-r12}

  push {r0-r12}
    mov r0, #1
    bl draw_paddle_player
  pop {r0-r12}

  push {r0-r12}
    mov r0, #1
    bl draw_paddle_ai
  pop {r0-r12}

  ; wait before refreshing screen again
  push {r0-r12}
    mov r0, BASE
    mov r1, $5000
    bl TIMER
  pop {r0-r12}

  b refresh_screen

; update game state (positions etc) based on game rules
update_state:
  ldr r0, [ball_x]
  ldr r1, [ball_y]
  ldr r2, [ball_direction]

  push {r0-r12, lr}
    bl check_ball_collision ; change ball direction if needed
  pop {r0-r12, lr}

  push {r0-r12, lr}
    bl control_paddle_ai ; move ai paddle with magic
  pop {r0-r12, lr}

  push {r0-r12, lr}
    bl control_paddle_player ; move player paddle based on input
  pop {r0-r12, lr}

  ; branch based on ball direction
  cmp r2, #0
    beq move_ball_SE
  cmp r2, #1
    beq move_ball_NE
  cmp r2, #2
    beq move_ball_NW
  cmp r2, #3
    beq move_ball_SW

  b ball_move_endif ; if none of the above are true skip ahead

  move_ball_SE:
    add r0, #2
    add r1, #2
    b ball_move_endif

  move_ball_NE:
    add r0, #2
    sub r1, #2
    b ball_move_endif

  move_ball_NW:
    sub r0, #2
    sub r1, #2
    b ball_move_endif

  move_ball_SW:
    sub r0, #2
    add r1, #2
    b ball_move_endif

  ball_move_endif:

  ; reset the ball position of out of bounds (hits left or right edge)

  ; left edge of screen
  cmp r0, #0
  ble reset_ball

  ; right edge of screen
  mov r3, SCREEN_X AND $FF00
  orr r3, SCREEN_X AND $00FF
  sub r3, BALL_WIDTH
  cmp r0, r3
  bge reset_ball

  ; if not out of bounds then skip over, do not reset
  b continue_ball
  
  reset_ball:
    mov r0, 250
    mov r1, 200
  
  continue_ball:

  str r0, [ball_x]
  str r1, [ball_y]

  bx lr

check_ball_collision:
  ldr r0, [ball_x]
  ldr r1, [ball_y]
  ldr r2, [ball_direction]
  ldr r3, [paddle_player_y]
  ldr r4, [paddle_ai_y]

  ; check ball/ai paddle collision
  ldr r5, [paddle_ai_x]
  sub r5, BALL_WIDTH
  cmp r0, r5
  bge test_paddle_ai_collision

  ; check ball/player paddle collision
  ldr r5, [paddle_player_x]
  add r5, #20
  cmp r0, r5
  ble test_paddle_player_collision

  ; if the ball hasnt reached the paddles yet
  b test_paddle_endif
  
  test_paddle_ai_collision:
    add r9, r1, BALL_WIDTH ; position at bottom of ball
    add r10, r4, PADDLE_HEIGHT ; position at bottom of paddle

    ; first test if position at bottom of ball >= top of paddle
    cmp r9, r4
    bge test_ball_above_ai_bottom
    b test_paddle_endif

    ; then test if position at top of ball <= bottom of paddle
    test_ball_above_ai_bottom:
      cmp r1, r10
      ble bounce_ball_left

    b test_paddle_endif

  test_paddle_player_collision:
    add r9, r1, BALL_WIDTH ; position at bottom of ball
    add r10, r3, PADDLE_HEIGHT ; position at bottom of paddle

    ; first test if position at bottom of ball >= top of paddle
    cmp r9, r3
    bge test_ball_above_player_bottom
    b test_paddle_endif

    ; then test if position at top of ball <= bottom of paddle
    test_ball_above_player_bottom:
      cmp r1, r10
      ble bounce_ball_right

    b test_paddle_endif

  test_paddle_endif:

  ; check ball/floor collision
  mov r5, SCREEN_Y AND $FF00
  orr r5, SCREEN_Y AND $00FF
  sub r5, BALL_WIDTH
  cmp r1, r5
  bge bounce_ball_up

  ; check ball/ceiling collision
  mov r5, #0
  cmp r1, r5
  ble bounce_ball_down

  ; if no collision, skip ahead
  b bounce_ball_endif

  bounce_ball_up:
    cmp r2, #0 ; if SE
    moveq r2, #1 ; move NE
    cmp r2, #3 ; if SW
    moveq r2, #2 ; move NW
    b bounce_ball_endif

  bounce_ball_down:
    cmp r2, #1 ; if NE
    moveq r2, #0 ; move SE
    cmp r2, #2 ; if NW
    moveq r2, #3 ; move SW
    b bounce_ball_endif

  bounce_ball_left:
    cmp r2, #0 ; if SE
    moveq r2, #3 ; move SW
    cmp r2, #1 ; if NE
    moveq r2, #2 ; move NW
    b bounce_ball_endif

  bounce_ball_right:
    cmp r2, #2 ; if NW
    moveq r2, #1 ; move NE
    cmp r2, #3 ; if SW
    moveq r2, #0 ; move SE
    b bounce_ball_endif

  ; continue statement
  bounce_ball_endif:

  str r2, [ball_direction]

  bx lr

; move the player paddle, based on user input
; paddle automatically 'floats' up unless the button at GPIO10 is held
control_paddle_player:
  ldr r1, [ball_y]
  ldr r2, [paddle_player_y]

  mov r0, BASE
  orr r0, GPIO_OFFSET

  ; program GPIO 10 for input
  ldr r9, [r0, #4] ; read function register for GPIO 10 to 19
  bic r9, r9, #27
  str r9, [r0, #4]

  ldr r10, [r0, #52]
  tst r10, #1024
  bne input_pulled_low
  b input_pulled_high

  input_pulled_low: ; button is pressed, move paddle down
    add r5, r2, PADDLE_HEIGHT  ; bottom of paddle
    mov r6, SCREEN_Y AND $FF00
    orr r6, SCREEN_Y AND $00FF
    cmp r5, r6
    addlt r2, #2
    b input_endif

  input_pulled_high: ; button is released, move paddle up
    mov r6, #0
    cmp r2, r6
    subgt r2, #1
    b input_endif
  
  input_endif:

  str r2, [paddle_player_y]


  bx lr

; move the AI paddle
; tries to follow the y-value of the ball
control_paddle_ai:
  ldr r1, [ball_y]
  ldr r2, [paddle_ai_y]

  ;add r3, r1, #12   ; ball midpoint
  ;add r4, r2, #60   ; paddle midpoint
  add r5, r2, PADDLE_HEIGHT  ; bottom of paddle

  cmp r2, r1
  blt move_paddle_ai_down

  cmp r2, r1
  bgt move_paddle_ai_up

  b move_paddle_ai_endif
  
  move_paddle_ai_down:
    mov r6, SCREEN_Y AND $FF00
    orr r6, SCREEN_Y AND $00FF
    cmp r5, r6
    addlt r2, #1
    b move_paddle_ai_endif

  move_paddle_ai_up:
    mov r6, #0
    cmp r2, r6
    subgt r2, #1
    b move_paddle_ai_endif

  move_paddle_ai_endif:

  str r2, [paddle_ai_y]

  bx lr

; wait forever
; this is probably redundant and will never be called lol
Loop:
  b Loop

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

; includes
include "draw_screen_objects.asm"
include "FBinit8.asm"
include "timer2_2Param.asm"
include "flash.asm"
include "drawpixel.asm"
