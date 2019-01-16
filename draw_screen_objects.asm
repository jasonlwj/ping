;FILE draw_screen_objects.asm

; draw a 24 x 24 square 'ball'
draw_ball:
  ;params
  ;r0 = colour

  ldr r1, [ball_x]
  ldr r2, [ball_y]

  add r3, r1, BALL_WIDTH
  add r4, r2, BALL_WIDTH

  mov r5, r0

  ball_y_loop:
    ball_x_loop:
      push {r0-r12, lr}
        mov r0, r7
        mov r1, r1
        mov r2, r2
        mov r3, r5
        bl draw_pixel
      pop {r0-r12, lr}

      add r1, #1
      cmp r1, r3
      bls ball_x_loop 

    ldr r1, [ball_x]
    add r2, #1
    cmp r2, r4
    bls ball_y_loop
  
  ldr r2, [ball_y]

  bx lr

; draw the left-hand side paddle for the player to control
draw_paddle_player:
  ;params
  ;r0 = colour
  ldr r1, [paddle_player_x]
  ldr r2, [paddle_player_y]

  add r3, r1, PADDLE_WIDTH
  add r4, r2, PADDLE_HEIGHT

  mov r5, r0

  paddle_player_y_loop:
    paddle_player_x_loop:
      push {r0-r12, lr}
        mov r0, r7
        mov r1, r1
        mov r2, r2
        mov r3, r5
        bl draw_pixel
      pop {r0-r12, lr}

      add r1, #1
      cmp r1, r3
      bls paddle_player_x_loop
    
    ldr r1, [paddle_player_x]
    add r2, #1
    cmp r2, r4
    bls paddle_player_y_loop
  
  ldr r2, [paddle_player_y]

  bx lr

; draw the right-hand side paddle to be controlled by the 'AI'
draw_paddle_ai:
  ;params
  ;r0 = colour
  ldr r1, [paddle_ai_x]
  ldr r2, [paddle_ai_y]

  add r3, r1, PADDLE_WIDTH
  add r4, r2, PADDLE_HEIGHT

  mov r5, r0

  paddle_ai_y_loop:
    paddle_ai_x_loop:
      push {r0-r12, lr}
        mov r0, r7
        mov r1, r1
        mov r2, r2
        mov r3, r5
        bl draw_pixel
      pop {r0-r12, lr}

      add r1, #1
      cmp r1, r3
      bls paddle_ai_x_loop
    
    ldr r1, [paddle_ai_x]
    add r2, #1
    cmp r2, r4
    bls paddle_ai_y_loop
  
  ldr r2, [paddle_ai_y]

  bx lr