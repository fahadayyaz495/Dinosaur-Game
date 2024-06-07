include Irvine\Irvine32.inc           ; included library 
includelib Irvine\Irvine32.lib

border_x1 = 5         ; left boundary position
border_x2 = 57          ; right boundary position
horizontal_len = border_x2 - border_x1         ; length of horizontal boundary
border_y1 = 6         ; upper boundary position
border_y2 = 23          ; lower boundary position
vertical_len = border_y2 - border_y1          ; length of vertical boundary

.code

draw_boundary proc 

    ; Procedure takes no argument
    ; Procedure displays boundary 
    ; Procedure returns nothing

    mov ax,lightblue          ; ax = ligthblue -> boundary color
    call settextcolor

    mov al,'*'        ; al = '*' -> boundary character
    
    mov dl,border_x1
    mov dh,border_y1
    call gotoxy         ; cursor goto upper left of the boundary

    mov ecx,horizontal_len/2         ; half length of horizontal wall because of displaying space
    label0:
        call writechar         ; displaying upper wall
        inc dl
        inc dl
        call gotoxy         ; skip one space after each wall character to keep boundary similar
        loop label0
    call writechar         ; display last character in wall

    mov dl,border_x1
    mov dh,border_y1
    call gotoxy         ; cursor goto upper left of the boundary

    mov ecx,vertical_len         ; length of vertical wall
    label1:
        call writechar         ; displaying left wall
        inc dh
        call gotoxy         ; adjusting cursor 
        loop label1
    
    mov dl,border_x1
    mov dh,border_y2
    call gotoxy         ; cursor goto lower left of the boundary

    mov ecx,horizontal_len/2         ; half length of horizontal wall because of displaying space
    label2:
        call writechar         ; displaying lower wall
        inc dl
        inc dl
        call gotoxy         ; skip one space after each wall character to keep boundary similar
        loop label2
    call writechar         ; display last character in wall
    
    mov dl,border_x2 
    mov dh,border_y1
    call gotoxy         ; cursor goto upper right of the boundary

    mov ecx,vertical_len         ; length of vertical wall
    label3:
        call writechar         ; displaying right wall
        inc dh
        call gotoxy         ; adjusting cursor
        loop label3

    mov ax,white        
    call settextcolor          ; reset color
    
    ret 

draw_boundary endp

track_x = border_x1 + 1         ; track x position 
track_y = border_y2 - 3         ; track y position
track_len = 50          ; length of track

draw_track proc,
    track_colors_ptr:dword

    ; Procedure takes 1 argumemt
    ; 1. Colors offset for track
    ; Procedure displays track and swaps the colors of track
    ; Procedure returns nothing

    mov esi,track_colors_ptr

    mov dl,track_x
    mov dh,track_y
    call gotoxy         ; cursor goto the starting position of track 

    mov ecx,track_len/2         ; half length of track because of displaying 2 characters in each iteration
    label0:
        mov ax,[esi]         ; ax = color1 -> first color character
        call settextcolor
        mov al,'_'         ; al = '_' -> track character
        call writechar
        mov ax,[esi + 2]         ; ax = color2 -> second color character
        call settextcolor
        mov al,'_'         ; al = '_' -> track character
        call writechar
        loop label0

    mov ax,[esi]         ; ax = color1 -> first color character 
    call settextcolor
    mov al,'_'
    call writechar          ; displaying last character of the track

    mov ax,white          ; reset color
    call settextcolor

    mov ax,[esi]        ; swaping track colors
    xchg ax,[esi + 2]
    xchg ax,[esi]         ; to show track is moving swaping perform

    ret

draw_track endp

draw_dino proc,
    head_ptr:dword, body_ptr:dword, x_pos:byte, y_pos:byte, foot_ptr:dword

    ; Procedure takes 5 argumemts
    ; 1. Head offset 
    ; 2. Body offset
    ; 3. x position of foot
    ; 4. y position of foot
    ; 5. Foot offset
    ; Procedure displays dino and swap the foot position as only one foot is displaying
    ; Procedure returns nothing

    ; Dino:
    ;    .:>
    ;   ~()~
    ;    ^^
    ; from above representation of dino observe the position of cursor to display body and head

    mov esi,foot_ptr          ; offset foot

    mov ax,yellow         ; ax = yellow -> dino color
    call settextcolor

    mov dl,x_pos
    mov dh,y_pos
    call gotoxy         ; cursor goto the position of dino foot

    mov al,[esi]         ; al = foot if left has to be shown else al = ' '
    call writechar

    mov al,[esi + 1]          ; al = foot if right has to be shown else al = ' '
    call writechar

    dec dl 
    dec dh
    call gotoxy         ; cursor goto the position of dino body as observe above

    push dx         ; saving cursor position
    mov edx,body_ptr
    call writestring          ; displaying body
    pop dx

    dec dh
    call gotoxy         ; cursor goto the position of head of the dino as observe above

    mov edx,head_ptr
    call writestring          ; displaying head

    mov ax,white              
    call settextcolor          ; reset color

    mov al,[esi]        ; swaping foot position
    xchg al,[esi + 1]
    xchg al,[esi]         ; to show foot is moving swaping perform
       
    ret

draw_dino endp

pause_game proc

    ; Procedure takes no argument
    ; Procedure takes input to continue game
    ; Procedure returns nothing

    continue_input:
    call readchar         ; taking input to continue game
    cmp al,'p'         ; if p is entered continue the game else take input again
    jne continue_input

    ret

pause_game endp

min_jump_pos = track_y         ; minimum jump position is track position
max_jump_pos = min_jump_pos - 4         ; maximum jump position is 4 units above from track

update_position proc,
    jflag_ptr:dword, y_pos_ptr:dword
    
    ; Procedure takes 2 arguments
    ; 1. Jump flag offset
    ; 2. y position offset of foot
    ; Procedure updates y positon of dino based on jump flag
    ; Procedure also updates jump flag based on y position
    ; procedure returns nothing

    mov esi,jflag_ptr
    cmp byte ptr [esi],1         ; checking wehther jump flag is on or not
    jne going_back         ; if dino is at max height the flag will off, so, if off going back 

        mov esi,y_pos_ptr
        cmp byte ptr [esi],max_jump_pos         ; if flag is on check wehther foot is at max height or not 
        jng flag_off          ; if max height flag should be off else decrement y position on console to going up
            dec byte ptr [esi]
            jmp update_complete

        flag_off:         
            mov esi,jflag_ptr
            mov byte ptr [esi],0         ; jump flag is off
            jmp update_complete
    
    going_back:

        mov esi,y_pos_ptr
        cmp byte ptr [esi],min_jump_pos         ; check wehther dino is at ground or not while going down
        jnl update_complete
            inc byte ptr [esi]         ; if dino is not on ground increment y on console to going down
        
    update_complete:
    
    ret

update_position endp

draw_obstacle proc, 
    obstacle_ptr:dword, obstacle_len:byte, oflag_ptr:dword, x_pos_ptr:dword

    ; Procedure takes 4 arguments
    ; 1. Obstacle offset for displaying obstacle
    ; 2. Obstacle length for loop
    ; 3. Obstacle flag offset 
    ; 4. x position offset of obstacle
    ; Procedure displays obstacle within the boundary of the game
    ; Procedure updates the x position of obstacle
    ; Procedure also updates the flag on the basis of x position
    ; Procedure returns nothing

    mov ax,red         ; ax = red -> obsatcle color
    call settextcolor

    mov esi,x_pos_ptr
    dec byte ptr [esi]         ; updating the x position of obstacle

    mov dl,[esi]        
    mov dh,track_y         ; position of the start of obstacle and y is fix and equals to track_y

    mov esi,obstacle_ptr          ; obstacle offset
    movzx ecx,obstacle_len         ; obstacle length for loop

    label0:
        cmp dl,border_x2          ; compare x position of obstacle character with right boundary
        jnl out_loop          ; if outside don't display and break the loop

            cmp dl,border_x1         ; compare x position of obstacle character with left boundary
            jng skip_obstacle         ; if outside just skip the display instruction 
            call gotoxy         ; cursor goto the position of obstacle character 
            mov al,[esi]
            call writechar          ; displaying obstacle character by character
        
        skip_obstacle:
        inc esi
        inc dl         ; increment the x position and obstacle character
        loop label0

    out_loop:

    cmp dl,border_x1 + 1         ; checking current position of cursor 
    jnl obstacle_done         ; if cursor at first position after left boundary reset actual x position of obstacle 
    mov esi,x_pos_ptr 
    mov byte ptr [esi],border_x2          ; reseting x position of obstacle

    mov esi,oflag_ptr         ; off the obstacle flag so new one would generate
    mov byte ptr [esi],0

    obstacle_done:
    mov ax,white          ; reset color     
    call settextcolor       

    ret 

draw_obstacle endp

check_life proc,
    ft_ptr:dword, ft_x:byte, ft_y:byte, ob_x:byte, ob_len:byte

    ; Procedure takes 5 arguments
    ; 1. Foot offset to check foot is left or right as one is displaying at a time
    ; 2. x position of foot
    ; 3. y position of foot
    ; 4. x position of obstacle
    ; 5. Obstacle length for loop
    ; Procedure checks wehther dino is died or not by checking foot's position and obstacle's position
    ; Procedure returns 0 for died and 1 for life to 'al' register

    cmp ft_y,track_y         ; checking dino is on the track or not
    jl life         ; if dino is jumping then alive

        mov al,ft_x         ; x position of left foot 
        mov esi,ft_ptr
        cmp byte ptr [esi],'^'         ;  checking if left foot is displaying
        je foot_found 
        inc al         ; if right foot is displaying increment the position in 'al' register

        foot_found:
        cmp ob_x,al         ; checking if obstacle is right side the dino foot then alive
        jg life         
    
    check_died:
        movzx ecx,ob_len         ; length of obstacle
        label0:
            cmp al,ob_x         ; checking each character of obstacle with foot position
            jne continue_checking          ; if not equal check next one
            mov al,0         ; if died return 0 to 'al' register
            je check_done
            continue_checking:
            inc ob_x         ; next position
            loop label0

    life:
    mov al,1         ; if alive return 1 to 'al' register
    check_done:
    ret

check_life endp

draw_bonus proc, 
    point:byte, x_pos_ptr:dword, y_pos_ptr:dword, bflag_ptr:dword

    ; Procedure takes 4 arguments
    ; 1. Bonus point
    ; 2. x position of bonus point
    ; 3. y position of bonus point
    ; 4. Bonus flag offset
    ; Procedure erases previously dispalyed bonus 
    ; Procedure updates the x and the y position of bonus
    ; Procedure displays bonus at updated position and also updates the flag
    ; Procedure returns nothing

    mov ax,lightgreen         ; ax = lightgreen -> bonus color
    call settextcolor

    mov esi,x_pos_ptr
    mov dl,[esi]
    mov esi,y_pos_ptr
    mov dh,[esi]
    call gotoxy         ;  cursor goto the previous position of bonus to erase previous one

    mov al,' '
    call writechar         ; erasing previous bonus if any
    
    mov esi,x_pos_ptr
    dec byte ptr [esi]         ; updating the x position of bonus
    mov dl,[esi]         ; setting x position for cursor

    mov esi,y_pos_ptr
    mov al,[esi]        ; updating the y position of bonus by swaping
    xchg al,[esi + 1]
    xchg al,[esi]          ; to move bonus sinusoidally swaping perform
    mov dh,[esi]

    call gotoxy         ;  cursor goto the position updated position of bonus

    cmp dl,border_x1          ; checking x position with left wall wether it is outside or not
    jng flag_off          ; if outside don't display jump to off the flag

    movzx eax,point
    call writedec         ; displaying bonus
    jmp bonus_done         ; don't off the flag just skip

    flag_off:
    mov esi,bflag_ptr         ; off the bonus flag so new one would generate
    mov byte ptr [esi],0

    bonus_done:
    mov ax,white          ; reset color     
    call settextcolor       

    ret 

draw_bonus endp

check_bonus proc,
    ft_x:byte, ft_y:byte, point_x:byte, point_y:byte, bflag_ptr:dword

    ; Procedure takes 5 arguments
    ; 1. x position of foot 
    ; 2. y position of foot
    ; 3. x position of bonus
    ; 4. y position of bonus
    ; 5. Bonus flag offset
    ; Procedure checks wehther bonus is catch or not by checking dino's position and bonus's position
    ; Procedure returns 0 for not catch and 1 for catch to 'al' register

    mov al,ft_x
    add al,2         ; maximum x position of dino's body
    
    cmp al,point_x        ; checking x position with bonus x position 
    jl not_get         ; if bonus is right side of the body then bonus is not caught yet

        check_x:
            ; there are 4 different x positions for body  
            mov ecx,4
            label0:
                cmp al,point_x         ; checking each position with bonus x position
                je check_y         ; if equal check y position
                dec al
                loop label0
                jmp not_get         ; if no x position is same then bonus is not caught 

        check_y:
            ; there are 2 different y positions for body     
            mov al,ft_y               
            dec al         ; y position above the foot 
            cmp al,point_y         ; checking first y position which is above the foot
            je get         ; if equal then bonus is caught
            dec al
            cmp al,point_y         ; checking second y position which is head position
            je get         ; if equal then bonus is caught
            jmp not_get         ; bonus is not caught
        
    get:
    mov esi,bflag_ptr         
    mov byte ptr [esi],0         ; off the bonus flag so new one would generate
    mov al,1         ; if bonus is caught return 1 to 'al' register
    ret

    not_get:
    mov al,0          ; if bonus is not caught return 0 to 'al' register
    ret

check_bonus endp

end
