include Irvine\Irvine32.inc           ; included library 
includelib Irvine\Irvine32.lib

; prototypes of all procedures

draw_boundary proto

draw_track proto,
    track_colors_ptr:dword

draw_dino proto,
    head_ptr:dword, body_ptr:dword, x_pos:byte, y_pos:byte, foot_ptr:dword

pause_game proto

update_position proto,
    jflag_ptr:dword, y_pos_ptr:dword

draw_obstacle proto, 
    obstacle_ptr:dword, obstacle_len:byte, oflag_ptr:dword, x_pos_ptr:dword
    
check_life proto,
    ft_ptr:dword, ft_x:byte, ft_y:byte, ob_x:byte, ob_len:byte

draw_bonus proto, 
    point:byte, x_pos_ptr:dword, y_pos_ptr:dword, bflag_ptr:dword

check_bonus proto,
    ft_x:byte, ft_y:byte, point_x:byte, point_y:byte, bflag_ptr:dword

.data 

    game_title byte "Dino Game",0          ; game title
    game_play_msg byte "Do you want to play game again?",0         ; Ask message
    game_over byte "Game Over",0         ; game over message 
    congratulation byte "You achieved highest score!",0         ; congratulation message

    score_msg byte "Your Score: ",0         ; score message
    highest_score_msg byte "Highest score: ",0          ; highest score message
    score dword 0          ; default score is 0
    high_score dword 0         ;  default high score is 0

    file byte "score.txt",0          ; file name
    file_handler dword ?          ; handler for file
    buffer_size = 10         ;  max buffer size
    buffer byte buffer_size dup(?)         ; buffer for file reading and writing
    byte_reads dword ?          ; bytes read or write to file
    
    track_colors word blue,yellow          ; track colors
    speed dword 150         ; defualt speed delay is 200

    head byte " .:>",0          ; dino head
    body byte "~()~",0          ; dino body
    foot byte '^',' '         ; dino foot
    foot_x byte 12         ; default x position of dino foot is 12
    foot_y byte 20         ; default y position of dino foot is track position which is 20

    blank_head byte "    ",0          ; blank dino head
    blank_body byte "    ",0          ; blank dino body
    blank_foot byte ' ',' '         ; blank dino foot
    last_foot_x byte ?          ; last foot x position
    last_foot_y byte ?          ; last foot y position

    jump_flag byte 0          ; default jump flag is off

    obstacle_1 byte "<|>"          ; obsatcle 1
    obstacle_2 byte "<##>"          ; obstacle 2     
    obstacle_3 byte "<$-$>"          ; obstacle 3
    obstacle_x byte 57         ; default x position of obstacle is right boundary which is 57
    obstacle_flag byte 0          ; default obstacle flag is off
    obstacle_ptr_rand dword ?          ; pointer for one of the 3 obstacles
    obstacle_len_rand byte ?          ; length of selected obsatcle

    obstacle_extra byte "<~!~>"         ; extra obstacle
    obstacle_x_extra byte ?         ; x position of extra obstacle
    obstacle_flag_extra byte 0          ; default extra obstacle flag is off

    bonus byte ?          ; bonus point
    bonus_x byte ?          ; x position of bonus
    bonus_y byte 14,15          ; y positions of bonus
    bonus_flag byte 0         ; default bonus flag is off

    target_score dword 100         ; default target score is 100

.code 

main proc

    game_start:

        call waitmsg          ; before restarting game display wait message
        call clrscr         ;  clear the screen when restart game

        mov ax,white
        call settextcolor          ; set white color default

        call crlf
        mov edx,offset highest_score_msg
        call writestring          ; displaying highest score message

    initialize:         ; resetting default values when restart the game

        mov score,0         ; default score
        mov high_score,0         ; default highest score
        mov speed,150          ; defalt speed delay
        mov foot_x,12          ; default x position of foot
        mov foot_y,20          ; default y position of foot
        mov jump_flag,0         ; default jump flag is off
        mov obstacle_flag,0         ; default obstacle flag is off
        mov obstacle_flag_extra,0         ; default extra bstacle flag is off
        mov obstacle_x,57          ; default x position of obstacle
        mov target_score,100         ; default target score

    highest_score_reading: 
        
        mov edx,offset file
        call openinputfile         ; opening file to read highest score
        cmp eax,INVALID_HANDLE_VALUE 
        je error_label         ; if file does not open jump to error_label
        mov file_handler,eax          ; getting file handler as the file is opened

        mov edx,offset buffer 
        mov ecx,buffer_size         ; max bytes to read
        call readfromfile          ; read highest score from file 
        mov byte_reads,eax          ; eax counts number of bytes actually read

        mov eax,file_handler
        call closefile         ; closing file

        mov edx,offset buffer
        mov ecx,byte_reads
        call parsedecimal32         ; converting string value to integer value from buffer
        mov high_score,eax         ; saving high score

    display_high_score:
        call writedec         ; displaying highest score
        call crlf
    
    score_message:

        call crlf
        mov edx,offset score_msg
        call writestring          ; displaying score message
        
    game_border:

        call draw_boundary         ; drawing boundary

        mov dl,27
        mov dh,8
        call gotoxy         ; cursor goto center of boundary
        mov edx,offset game_title
        call writestring         ; displaying game title

        call randomize         ; use for randomrange procedure

    game_loop:
        
        mov dl,12
        mov dh,3
        call gotoxy         ; cursor goto the position after score message
        mov eax,score
        call writedec          ; displaying current score

        ; drawing track with two alternative colors
        invoke draw_track, offset track_colors
        
        ; drawing blank dino to erase previous if its position changed as dino jumps
        invoke draw_dino, offset blank_head, offset blank_body, last_foot_x, last_foot_y, offset blank_foot
        ; drawing dino with only one foot at alternative position
        invoke draw_dino, offset head, offset body, foot_x, foot_y, offset foot

        obstacle_process:

            cmp obstacle_flag,0         ; checking obstacle flag is off or on
            jne flag_on          ; if already on don't create new one and skip following instructions else create new one

                ; there are 3 obstacles which will come randomly
                mov eax,3         
                call randomrange         ; generate random number 0, 1, or 2

                cmp eax,0         ; if 0 is random create obstacle_1 in .data section
                jne check_1         ; else check for 1
                    mov esi,offset obstacle_1
                    mov obstacle_ptr_rand,esi         ; setting offset obstacle_1 for obstacle_ptr
                    mov obstacle_len_rand,lengthof obstacle_1
                    jmp flag_on         ; on the flag and continue the game

                check_1:
                cmp eax,1         ; if 1 is random create obstacle_2 in .data section
                jne check_2         ; else check for 2
                    mov esi,offset obstacle_2
                    mov obstacle_ptr_rand,esi         ; setting offset obstacle_2 for obstacle_ptr
                    mov obstacle_len_rand,lengthof obstacle_2
                    jmp flag_on         ; on the flag and continue the game

                check_2:
                    mov esi,offset obstacle_3
                    mov obstacle_ptr_rand,esi         ; setting offset obstacle_3 for obstacle_ptr
                    mov obstacle_len_rand,lengthof obstacle_3

        flag_on:

            mov obstacle_flag,1         ; on the flag 

            ; drawing obstacle using x position offset also updating the x position of obstacle and the obstacle flag 
            invoke draw_obstacle, obstacle_ptr_rand, obstacle_len_rand, offset obstacle_flag, offset obstacle_x

            ; checking wether dino is alive or not
            invoke check_life, offset foot, foot_x, foot_y, obstacle_x, obstacle_len_rand
                cmp al,0         ; if return 0 to 'al' register then died
                je died 
        
        extra_obstacle:

            ; there is an extra obstacle which will be craeted after some random position on the basis of its flag
            cmp obstacle_flag_extra,0         ; checking obstacle flag is off or on for extra obstacle
            jne extra_flag_on          ; if already on don't create new one and skip following instructions else create new one

                mov al,obstacle_x
                mov obstacle_x_extra,al          ; copy the current position of obstacle_1,2,3 (currently active)
                mov eax,25
                call randomrange           ; generate random number between 0 and 25
                add al,10         ; add 10 to random number to keep some distance in extra obstacle
                add obstacle_x_extra,al         ; add the number to x position of extra obstacle

        extra_flag_on:

            mov obstacle_flag_extra,1         ; on the flag

            ; drawing extra obstacle using x position offset also updating the x position of extra obstacle and the obstacle flag extra
            invoke draw_obstacle, offset obstacle_extra, lengthof obstacle_extra, offset obstacle_flag_extra, offset obstacle_x_extra
            
            ; checking wether dino is alive or not
            invoke check_life, offset foot, foot_x, foot_y, obstacle_x_extra, lengthof obstacle_extra
                cmp al,0         ; if return 0 to 'al' register then died
                je died 

        bonus_process:

            cmp bonus_flag,0          ; checking bonus flag is on or off 
            jne bonus_flag_on          ; if flag is on don't generate new one

                mov eax,10
                call randomrange
                mov bonus,al         ; bonus generate randomly between 0 to 9

                mov eax,30
                call randomrange         ; x position generate randomly for 30 different positions
                add eax,20          ; adjusting position after dino's position
                mov bonus_x,al

        bonus_flag_on:

            mov bonus_flag,1         ; on the bonus flag

            ; drawing the bonus, erasing previous one and also updating bonus flag on the basis of x position
            invoke draw_bonus,bonus, offset bonus_x, offset bonus_y, offset bonus_flag
            
            mov dl,1
            mov dh,25
            call gotoxy         ; cursor goto the last of console to take input
            call  readkey         
            jz continue_game         ; if user enters something, zero flag will off

        input_process:

            cmp al,'p'          ; if p is entered pause the game else check input for ' ' character
            jne check_space_enter
            call pause_game         ; taking input to continue game
            jmp continue_game           ; if something else is entered just continue the game
            
            check_space_enter:
            cmp al,' '          ; if ' ' is entered for jump the jump flag will be on if it is off before
            jne continue_game          ; if something else is entered just continue the game
            
                cmp foot_y,20         ; if dino is already jumping continue the game 
                jne continue_game

                mov jump_flag,1         ; jump flag is on

        continue_game:

            ; saving last position of dino for erasing when dino's position is changed
            mov al,foot_x
            mov last_foot_x,al
            mov al,foot_y
            mov last_foot_y,al

            ; updating the position of dino on basis of jump flag also updating jump flag
            invoke update_position, offset jump_flag, offset foot_y

            ; checking wether dino caught bonus or not, also update bonus flag if caught
            invoke check_bonus, foot_x, foot_y, bonus_x, bonus_y, offset bonus_flag
                cmp al,1         ; if 1 return to 'al' register then bonus is caught
                jne catch

            movzx eax,bonus
            add score,eax         ; if bonus is caught then add it to the score

        catch:

            mov eax,score
            cmp eax,target_score         ; checking wether target score is achieved or not to increase speed
            jl speed_delay          
                sub speed,20         ; increase speed by 20 units
                add target_score,100           ; updating target score 

        speed_delay:

            inc score          ; increment the score

            mov eax,speed          
            call delay         ; controlling speed by delay procedure

            mov dl,1
            mov dh,25
            call gotoxy         ; cursor goto the last position

    jmp game_loop

    died:

        mov dl,27
        mov dh,10
        call gotoxy         ; cursor goto center of boundary in 5th row
        mov edx,offset game_over
        call writestring         ; displaying game over message

        mov dl,1
        mov dh,25
        call gotoxy         ; cursor goto the last position

        call crlf
        mov eax,score
        mov edx,offset score_msg
        call writestring          ; displaying score 
        call writedec
        call crlf

        cmp eax,high_score         ; checking wether highscore is achieved or not
        jng play_again         ; if not achieved then don't update high score in file

            call crlf
            mov edx,offset congratulation
            call writestring          ; displaying congratulation message 
            call crlf

            mov edx,offset file
            call createoutputfile         ; opening file to write highest score
            cmp eax,INVALID_HANDLE_VALUE 
            je error_label         ; if file does not open jump to error_label
            mov file_handler,eax          ; getting file handler as the file is opened
            
            mov eax,score
            mov ecx,0
            mov ebx,10
            ; converting integer to string to write in file
            label2:
                mov edx,0
                div ebx         ; getting remainder
                add edx,'0'         ; adding '0' character to convert remainder in string
                push edx         ; saving integer characters in stack as only remainder converts integer to string in reverse order
                inc ecx         ; counting digits
                cmp eax,0         ; if integer not equal 0 seperate next remainder
                jne label2    

            mov byte_reads,ecx          ; bytes to write in file 
            mov esi,offset buffer          ; buffer offset to write in file
            ; loading charcter integers in buffer 
            label3:
                pop edx
                mov byte ptr [esi],dl         ; loading from stack
                inc esi
                loop label3        

            mov eax,file_handler
            mov edx,offset buffer
            mov ecx,byte_reads
            call writetofile         ; writing new high score in file           

            mov eax,file_handler
            call closefile         ; closing file    

    play_again:
        mov ebx,offset game_title
        mov edx,offset game_play_msg
        call msgboxask         ; opening popup window to ask play game
        cmp eax,IDNO 
        je game_off         ; if press "no" game will be off
        
    jmp game_start

    error_label:

        mov eax,0          ; default high score
        jmp display_high_score

    game_off:         ; off the game

    exit
    
main endp

end main
