;===============================================================================
;================================Code Segment 1=================================
;===============================================================================
call change_To_DS_7c0h		 		; Initial memory 7c0h

mov DI, [default_keyboard_mode]
jmp	start_Program

;Clear changes - make keyboard keys back to default.
clear_Changes :
mov DI, 123h
mov [default_keyboard_mode], DI
mov [setting_mode], DI
call set_Default_Keyboard
jmp go_To_Menu

print_Input:
call set_Most_Updated_Memory

start_Program :
call set_Video_Mode
;===============Prepare memory for data segment sector 2==============
mov AX, 800h						; Prepare memory 800h:0000h
mov ES, AX
mov BX, 0

mov AX, 0201h						; Read Sectors From Drive / Sectors To Read Count
mov CX, 2							; Cylinder / Sector 2
mov DX, 80h							; Head / Drive HDD1
int 13h
;=====================================================================

mov SI, text_input
call print_Message

push DX
mov DX, 171bh						; Row/Column
call set_Cursor_At
mov SI, esc_message
call print_Message
pop DX

call 800h:0000h

call change_To_DS_7c0h				; Back to memory 7c0h
mov [default_keyboard_mode], DI
jmp go_To_Menu

change_Button:

call set_Video_Mode
;===============Prepare memory for data segment sector 3==============
mov AX, 1000h						; Prepare memory 1000h:0000h
mov ES, AX
mov BX, 0

mov AX, 0201h						; Read Sectors From Drive / Sectors To Read Count
mov CX, 3							; Cylinder / Sector 3
mov DX, 80h							; Head / Drive HDD1
int 13h
;====================================================================

call set_Default_Keyboard

call 1000h:0000h

call change_To_DS_7c0h				; Back to memory 7c0h

go_To_Menu:

call set_Video_Mode
;===============Prepare memory for data segment sector 4==============
mov AX, 2000h						; Prepare memory 2000h:0000h
mov ES, AX
mov BX, 0

mov AX, 0201h						; Read Sectors From Drive / Sectors To Read Count
mov CX, 4							; Cylinder / Sector 4
mov DX, 80h							; Head / Drive HDD1
int 13h
;====================================================================

call 2000h:0000h

call change_To_DS_7c0h				; Back to memory 7c0h
cmp DI, 321h
	je finish_update_memory
	
;;;;;;;;;;;;;;;;Check what was pressed;;;;;;;;;;;;;;;;
	cmp DI, 0
		je clear_Changes
	cmp DI, 1
		je change_Button
	cmp DI, 2
		je change_Button			;Create Keyboard Setting
	cmp DI, 3
		je set_My_Setting
	cmp DI, 4
		je print_Input
	cmp DI, 5
		je exit_Program
		
;;;;;;;;;;;;;;;;Show Keyboard Setting;;;;;;;;;;;;;;;;;
set_My_Setting :

call set_Video_Mode

mov DX, 020bh						; Row/Column
call set_Cursor_At
mov SI, my_keyboard_setting
call print_Message
mov DX, 0500h						; Row/Column
call set_Cursor_At

;Preview all changes in keyboard
;Once pressed this option in menu you can view the all key values when pressed.
call set_Default_Keyboard

call show_Keyboard_Settings
	
call change_To_DS_7c0h				; Back to memory 7c0h
mov DX, 171bh						; Row/Column
call set_Cursor_At
mov SI, esc_message
call print_Message
wait_for_esc:
	mov AH, 0
	int 16h
	cmp AL, 01bh
		je go_To_Menu				; When press 'ESC'
jmp wait_for_esc
	
exit_Program:
call set_Video_Mode
;====================================================================
jmp $                             	; Enter infinite loop (Lock CPU)
;=============================FUNCTIONS==============================
;Go to memory 7c0h
change_To_DS_7c0h :
	mov AX, 7c0h
	mov DS, AX
	ret
	
;Show video mode
set_Video_Mode :
	mov AX, 13h
	int 10h
	ret

;Prints a message on screen. SI = Message
print_Message :
	mov BL, 1111b					; Color of input
	print:
		lodsb						; Load string from SI to AL until end of string.
		cmp AL, 0
			je skip
		call print_Char
	jmp print
	skip:
	ret

;Prints character
print_Char :
	mov AH, 0eh
	mov BH, 0						; Page no.
	int 10h
	ret
	
;Set default setting to keyboard
set_Default_Keyboard :
	mov CX, [setting_mode]
	cmp CX, 123h
		jne skip_here
	mov BX, 1000h
	mov DS, BX
	mov SI, 65
	mov CX, 26
	starting_loop:
			mov [BX], SI
			mov [BX + 27], SI
			inc BX
			inc SI
	loop starting_loop
	mov AX, 7c0h
	mov DS, AX
	mov CX, 0
	mov [setting_mode], CX
	skip_here:
	ret
	
;set Cursor
set_Cursor_At :
	mov AH, 02
	mov BX, 0
	int 10h
	ret
	
set_Most_Updated_Memory :
	mov DI, 321h
	jmp go_To_Menu
	finish_update_memory:
	mov DI, [default_keyboard_mode]
	ret

;This procedure will allow the user to see the full character setting.	
show_Keyboard_Settings :
	mov BX, 1000h
	mov DS, BX
	mov CX, 26
	mov DI, 0
	preview_Keyboard_Setting :
		pusha
		mov AL, 32
		call print_Char
		popa
		mov AL, [BX]
		push BX
		mov BL, 1100b
		mov AH, 0eh
		int 10h
		mov BL, 1111b
		mov AL, 204
		int 10h
		mov AL, 205
		times 2 int 10h
		mov AL, 175
		int 10h
		pop BX
		mov AL, [BX + 27]
		mov AH, 0eh
		push BX
		mov BL, 1111b					; Set Color
		int 10h
		pop BX
		inc BX
		inc DI
		mov AX, DI
		push CX
		mov CL, 3						; Divides the alphabet into 3 columns
		div CL
		;Add space between columns
		push BX
		push AX
		mov AH, 03
		mov BH, 0
		int 10h
		pop AX
		cmp AH, 0
			je print_line_only
		add DL, 9
		call set_Cursor_At
		pop BX
		pop CX
		jmp no_skip_line
		print_line_only:
		;Move down two lines
		mov DL, 0
		add DH, 2
		call set_Cursor_At
		pop BX
		pop CX
		no_skip_line:
	loop preview_Keyboard_Setting
ret
;=============================VARIABLES==============================
text_input db 'Message : ', 0
setting_mode dw 123h
my_keyboard_setting db 'My Keyboard Setting', 0
esc_message db '[ESC] - Menu', 0
default_keyboard_mode dw 123h
;====================================================================
times 510 - ($-$$) db 0            	; Fill empty bytes to binary file 
dw 0aa55h                          	; Define MAGIC number at byte 512 
;===============================================================================
;================================Code Segment 2=================================
;===============================================================================
start_Segment_2:

mov AX, 800h
mov DS, AX

mov [type_mode - 512], DI

;First line keyboard layout. Start point (15,22)
mov CX, 10							; No. of sqaures
mov BX, 0f3eh						; Start point of sqaure (column/row)
mov AL, 1100b						; Set color to pixels in keyboard line
call draw_Keyboard

;Second line keyboard layout. Start point (22,47)
mov CL, 9							; No. of sqaures
mov BX, 1657h						; Start point of sqaure (column/row)
call draw_Keyboard

;Third line keyboard layout. Start point (31,72)
mov CL, 7							; No. of sqaures
mov BX, 1f70h						; Start point of sqaure (column/row)
call draw_Keyboard

mov SI, 0							; Counter SI = 0 for ASCII variable

;First keyboard line letters print.
mov BX, 0308h						; Cursor start point (column/row)
mov CL, 10							; No. of ASCII characters
mov DI, 0
call insert_ASCII

;Second keyboard line letters print.
mov BX, 040bh						; Cursor start point (column/row)
mov CL, 9							; No. of ASCII characters
inc DI
call insert_ASCII

;Third keyboard line letters print
mov BX, 050eh						; Cursor start point (column/row)
mov CL, 7							; No. of ASCII characters
inc DI
call insert_ASCII

mov [type_mode - 512], BX

;;;;;;;;;;;;Starting the input with keyboard display;;;;;;;;;;;;;

call set_Cursor

;Print message for Input characters
mov SI, 0
call character_Input_Fill

mov DI, [type_mode - 512]

retf  
;=============================FUNCTIONS==============================
;Draw keyboard
draw_Keyboard :
	mov [add_row - 512], BL
	mov [add_column - 512], BH
	call draw_Square
	add BH, 24						; Add to column
	loop draw_Keyboard
	call clear_Variables
	ret
	
;Clear variables
clear_Variables :
	mov BX, 0
	mov [add_row - 512], BL
	mov [add_column - 512], BH
	ret

;Draw a square in video mode
draw_Square :
	pusha
	;Start point (x,y+24) --> (x,y)
	mov DL, [add_row - 512]
	mov CL, 24
	mov BX, 0
	call line_Vertical	
	;Start point (x+24,y) --> (x,y)
	mov DL, [add_row - 512]
	mov CL, 24
	call line_Horizontal
	;Start point (x+24,y+24) --> (x+24,y)
	mov DL, [add_row - 512]
	mov CL, 24
	mov BX, 24
	call line_Vertical
	;Start point (x+24,y+24) --> (x,y+24)
	mov DX, 24
	add DL, [add_row - 512]
	mov CL, 24
	call line_Horizontal
	popa
	ret

;Draw vertical line
line_Vertical :
	push CX
	mov CX, BX
	add CL, [add_column - 512]
	call draw_Pixel
	inc DX
	pop CX
	loop line_Vertical
	ret
	
;Draw horizontal line
line_Horizontal :
	push CX
	add CL, [add_column - 512]
	call draw_Pixel
	pop CX
	loop line_Horizontal
	ret

;Draw pixel at CX = Column, DX = Row, AL = Color
draw_Pixel :
	push BX
	mov BX, 0
	mov AH, 0Ch
	int 10h
	pop BX
	ret
	
;Prints the keyboard letters
insert_ASCII :
	mov [add_row - 512], BL
	mov [add_column - 512], BH
	call set_Cursor
	call save_Key_In_Memory
	call print_ASCII
	inc SI							; Go through ASCII letters (variable)
	add BH, 3						; Add to column
	loop insert_ASCII
	call clear_Variables
	ret

;Set cursor at position : DH = row, DL = column
set_Cursor :
	pusha
	mov AH, 02
	mov BX, 0						; Page
	mov DH, [add_row - 512]			; Set cursor (row)
	inc DH
	mov DL, [add_column - 512]		; Set cursor (column)
	int 10h
	popa
	ret
	
;Saves the key in memory from 800h:0000
save_Key_In_Memory :
	pusha
	;Three lines that make default settings.
	mov BX, [type_mode - 512]	
	cmp BX, 123h
		jne no_save
	mov BX, [memory_counter - 512] 				; Starts from 800h:0000h
	mov DL, [ASCII + SI - 512]
	mov [BX], DL								; Save ASCII
	mov [BX + 3], DL							; Duplicate value in memory for key change.
	mov DL, [save_row_memory + DI - 512]		
	mov [BX + 1], DL							; Save the ASCII key row in memory
	mov DH, [save_column_memory + DI - 512]	
	mov [BX + 2], DH							; Save the ASCII key column in memory
	mov DH, 24
	add [save_column_memory + DI - 512], DH		; Prepare the next column pixel
	no_save:
	popa
	ret
	
;Prints letter, video mode
print_ASCII :
	pusha
	mov BX, [memory_counter - 512]
	mov AH, 09
	mov AL, [BX + 3]				; ASCII Character
	mov BX, 1111b					; Page/Color
	mov CX, 1						; No. of iterations
	int 10h
	mov DH, 4
	add [memory_counter - 512], DH				; Move forward with memory 3 bytes
	popa
	ret
	
;Input : AL = Uppercase characters
;Output : Prints on screen those letters and where is placed on the keyboard.
character_Input_Fill:
	;Input character to AL.
	mov AH, 0
	int 16h
	;Jumps if press on 'ESC' key.	
	cmp AL, 01Bh
		je stop_Typing
	;Jumps if reach character limit before smashing keyboard.
	cmp SI, 200
		je stop_Typing
	;Jumps if not in capital ASCII characters
	cmp AL, 64
		jle not_Found_ASCII
	cmp AL, 123
		jge not_Found_ASCII
	cmp AL, 90
		jle copy_character
	cmp AL, 96
		jle not_Found_ASCII
	sub AL, 32
	copy_character :
	push AX
	mov AX, 0
	call fill_Key_When_Pressed
	pop AX
	call check_For_Key_In_Memory
	;Output character from AL.
	push BX
	mov AH, 0Eh
	mov BL, 1010b					; Color of output text
	int 10h
	inc SI							; Count typed letters
	pop BX
	mov AL, 1010b					; Found key, color fill key sqaure
	mov [key_press_row - 512], BL
	mov [key_press_column - 512], BH
	call fill_Key_When_Pressed
	not_Found_ASCII :
	jmp character_Input_Fill
	stop_Typing :					; When user pressed 'ESC' key (ASCII - 01Bh) or 240 characters
	ret

;Fill in pressed key. Start point (15,22) - Top left keyboard key.
;Add 24 to column for next key.
;Add 25 to row for next row.
fill_Key_When_Pressed :
	mov BL, [key_press_row - 512]			; Key press top left corner [row] 
	mov BH, [key_press_column - 512]		; Key press top left corner [column]
	mov [add_row - 512], BL
	mov [add_column - 512], BH
	call fill_Square
	ret
	
;Input : AL = keyboard ASCII Character
;Return : BL = row, BH = column, AL = Updated ASCII character
check_For_Key_In_Memory :
	push DX
	mov BX, 800h 
	start:
		cmp [BX], AL
			je found_ASCII
		add BX, 4
	jmp start
	found_ASCII:
	mov DL, [BX + 1]				; Copy row from memory
	mov DH, [BX + 2]				; Copy column from memory
	mov AL, [BX + 3]				; Copy ASCII from memory
	mov BX, DX
	pop DX
	ret

;Fill key with color
fill_Square :
	mov CX, 6						; No. of lines
	mov DL, [add_row - 512]			; Starting point row
	add DL, 17
	draw_Lines :
		push CX
		mov CX, 23					; No. of pixels in line
		inc DX
		draw_All_Row :
			push CX
			add CL, [add_column - 512]		; Starting point column
			call draw_Pixel
			pop CX
		loop draw_All_Row
		pop CX
		loop draw_Lines
		call clear_Variables
	ret
;=============================VARIABLES==============================
add_row db 0
add_column db 0
memory_counter dw 800h
ASCII db 'Q','W','E','R','T','Y','U','I','O','P','A','S','D','F','G','H','J','K','L','Z','X','C','V','B','N','M'
save_row_memory db 62, 87, 112
save_column_memory db 15, 22, 31
key_press_row db 30
key_press_column db 15
type_mode dw 0
;====================================================================
times 1024 - ($-$$) db 0
;===============================================================================
;================================Code Segment 3=================================
;===============================================================================
start_Segment_3:

mov AX, 1000h
mov DS, AX

mov [change_mode - 1024], DI	
	
call print_Select_Text

cmp DI, 1
	je change_A_Character

mov DI, 65

;Changing all keyboard characters.
change_All_Keyboard_Characters :
	call set_Video_Mode_
	call print_Select_Text
	call set_Cursor_At_Position
	mov AX, DI						; Copy character (ASCII)
	mov BL, 1100b
	mov AH, 0eh
	int 10h
	call print_Symbols
	mov SI, 1
	call capital_Characters_Only
	mov BX, DI
	mov AH, BL
	xchg AL, AH
	push AX
	call save_All_New_Keyboard_Memory
	xchg AL, AH
	inc DI							; Move to the next character by order.
	cmp DI, 91
		je last_character			; When reach to letter 'Z'
	cmp DI, 66
		jne try_again_  			; When not letter 'A'
	mov DX, 1600h					; set row/column
	mov BX, character_next - 1024
	mov CX, end_character_next - character_next
	call print_Text
	mov DX, 1700h					; set row/column
	mov BX, character_esc - 1024
	mov CX, end_character_esc - character_esc
	call print_Text
	try_again_:
	mov AH, 0
	int 16h
	cmp AL, 01bh
		je back_to_menu				; When press 'ESC'
	cmp AX, 1c0dh					
		je change_All_Keyboard_Characters	; When press 'Enter'
	jmp try_again_
	last_character:
	mov DX, 1600h					; Set row/column
	mov BX, character_save - 1024
	mov CX, end_character_save - character_save
	call print_Text
	last_character_done:
		mov AH, 0
		int 16h
		cmp AX, 1c0dh
			je back_to_menu			; When press 'Enter'
	jmp last_character_done

;Select a new ASCII for old one.
change_A_Character :
	mov SI, 0
	call capital_Characters_Only
	mov AH, 0eh
	call print_Symbols
	mov SI, 1
	call capital_Characters_Only
	mov DX, 1600h
	mov BX, character_save - 1024
	mov CX, end_character_save - character_save
	call print_Text
	try_again:
	mov AH, 0
	int 16h
	cmp AX, 1c0dh					; Press 'Enter'
		je press_enter
	jmp try_again

press_enter:
push AX
mov AL, [old_and_new_ascii - 1024]			; Old ASCII
mov AH, [old_and_new_ascii - 1024 + 1]		; New ASCII
push AX
call save_All_New_Keyboard_Memory
pop AX	
back_to_menu:
	
retf	
;=============================FUNCTIONS==============================

;Prints the text on the top left corner.
print_Select_Text :
	pusha
	mov DX, 0
	mov BX, text_selection - 1024
	mov CX, end_text_selection - text_selection
	call print_Text
	popa
	ret

;Show video mode
set_Video_Mode_ :
	mov AX, 13h
	int 10h
	ret
	
;print only capital characters
capital_Characters_Only :
	push BX
	new_character:
	mov AH,0	
	int 16h
	cmp AL, 64
		jle new_character
	cmp AL, 123
		jge new_character
	cmp AL, 90
		jle copy_character_
	cmp AL, 96
		jle new_character
	sub AL, 32
	copy_character_ :
	mov [old_and_new_ascii - 1024 + SI], AL
	mov AH, 0eh
	mov BL, 1111b					; Color of character
	int 10h
	pop BX
	ret

;Print string
;DL = column, DH = row, CX = string length, BX = String
print_Text :
	mov BP, BX						; String offset
	mov AH, 13h
	mov AL, 1						; Write mode
	mov BH,  0						; Page no.
	mov BL, 1111b					; Color
	int 10h
	ret

;Print switch symbols (|==>)
print_Symbols :
	mov BL, 1111b
	mov AL, 204
	int 10h
	mov AL, 205
	int 10h
	mov AL, 205
	int 10h
	mov AL, 175
	int 10h
	ret
	
;Copy all the ASCII memory to memory 1000h:0000h
;AL = old ASCII, AH = new ASCII
save_All_New_Keyboard_Memory :
	pop DX							; The line of the call procedure
	pop AX							; Getting the information from ASCCI (new & old)
	push DX							; Stack the line of the calling procedure
	push BX
	mov BX, 1000h
	add BL, AL
	sub BX, 65
	mov [BX], AL
	mov [BX + 27], AH
	pop BX
	ret

;Set cursor at position : DH = row, DL = column
set_Cursor_At_Position :
	pusha
	mov AH, 02
	mov BX, 0						; Page
	mov DX, 1bh						; Set cursor (row/column)
	int 10h
	mov AH, 0eh
	mov AL, ' '
	int 10h
	mov AH, 02
	mov DX, 16h
	int 10h
	popa
	ret
;=============================VARIABLES==============================
text_selection db 'Select a character  : '
end_text_selection db 0
character_save db '[Enter] - Save & Exit'
end_character_save db 0
character_esc db '[ESC] - Save & Exit'
end_character_esc db 0
character_next db '[Enter] - Next'
end_character_next db 0
old_and_new_ascii db 0, 0
change_mode db 0
;====================================================================
times 1536 - ($-$$) db 0
;===============================================================================
;================================Code Segment 4=================================
;===============================================================================
start_Segment_4:

mov AX, 2000h
mov DS, AX

cmp DI, 321h
	je memory_Change

mov AL, 1111b						; Color of main square pixels
mov SI, 129							; Set height of square
mov DI, 203							; Set width of square
call draw_Square_Menu
mov SI, 17							; Start point row : 10 + SI
add [row_start - 1536], SI
mov CX, 6							; No. of reqtangles
draw:
	mov SI, 16
	add [row_start - 1536], SI
	mov SI, 16						; Set height of square
	mov DI, 203						; Set width of square
	call draw_Square_Menu
loop draw

mov DX, 0511h						; Set row/column
mov BX, menu - 1536
mov CX, 4
call print_String

mov DI, 0
mov SI, 0 
mov CX, 6							; No. of loops
mov DL, 07h							; Column of print
show_Options :
	push CX
	mov DH, [placements + SI - 1536]		; Set row
	mov BX, strings - 1536					; Set string variable
	add BX, DI								; Set position in string to print
	mov CL, [length_string + SI - 1536]		; Set length of string
	call print_String
	add DI, CX
	inc SI
	pop CX
loop show_Options

;;;;;;;;;;;;;;;;;;;;Here starts selection of option;;;;;;;;;;;;;;;;;;
mov DI, -1
mov DL, 07h
mov SI, 0
xor CX, CX
jmp arrow_Down
new_position:
	mov AH, 0
	int 16h
	cmp AH, 48h
		je arrow_Up
	cmp AH, 50h
		je arrow_Down
	cmp AX, 1c0dh
		je hit_Enter_Key
jmp new_position
	
memory_Change :
call changing_Memory_Of_Input

hit_Enter_Key:
retf
;=============================FUNCTIONS==============================
;Draw a square in video mode
;SI = Height, DI = Width
draw_Square_Menu :
	pusha
	mov DL, [row_start - 1536]		; Start point row
	mov CX, SI						; Number of pixels in height (left) 
	mov BX, 0
	call line_Vertical_Menu
	
	mov DL, [row_start - 1536]		; Start point row
	mov CX, DI						; Number of pixels in width (up)
	call line_Horizontal_Menu
	
	mov DL, [row_start - 1536]		; Start point row
	mov CX, SI						; Number of pixels in height (right)
	mov BX, DI
	call line_Vertical_Menu
	
	mov DX, SI
	add DL, [row_start - 1536]		; Start point row
	mov CX, DI						; Number of pixels in width (down)
	call line_Horizontal_Menu
	popa
	ret

;Draw vertical line
line_Vertical_Menu :
	push CX
	mov CX, BX
	add CL, [column_start - 1536]	; Start point column
	call draw_Pixel_Menu
	inc DX
	pop CX
	loop line_Vertical_Menu
	ret
	
;Draw horizontal line
line_Horizontal_Menu :
	push CX
	add CL, [column_start - 1536]	; Start point column
	call draw_Pixel_Menu
	pop CX
	loop line_Horizontal_Menu
	ret

;Draw pixel at CX = Column, DX = Row, AL = Color
draw_Pixel_Menu :
	pusha
	mov BX, 0
	mov AH, 0Ch
	int 10h
	popa
	ret

;Print string
;DL = column, DH = row, CX = string length, BX = String
print_String :
	mov BP, BX						; String offset
	mov AH, 13h
	mov AL, 1						; Write mode
	mov BH,  0						; Page no.
	mov BL, 1111b					; Color
	int 10h
	ret
	
;When user hits the 'UP' arrow key.
;Hitting arrow up will go up in Menu
arrow_Up :
	cmp DI, 0
		jle new_position
	mov BX, strings - 1536
	add BX, SI
	call print_String
	dec DI
	mov CL, [length_string + DI - 1536]		; Update length of new string
	sub SI, CX
	mov DH, [placements + DI - 1536] 		; Update placement of new string
	mov BX, strings - 1536					; Update new string
	add BX, SI
	call selected_String
	jmp new_position

;When user hits the 'DOWN' arrow key. 
;Hitting arrow down will go down in Menu	
arrow_Down :
	cmp DI, 5
		jge new_position
	mov BX, strings - 1536
	add BX, SI
	call print_String
	inc DI
	add SI, CX
	mov DH, [placements + DI - 1536] 		; Update placement of new string
	mov BX, strings - 1536					; Update new string
	add BX, SI
	mov CL, [length_string + DI - 1536]		; Update length of new string
	call selected_String
	jmp new_position

;Select a string
;DL = column, DH = row, CX = string length, BX = String
selected_String :
	mov BP, BX						; String offset
	mov AH, 13h
	mov AL, 1						; Write mode
	mov BH,  0						; Page no.
	mov BL, 1010b					; Color
	int 10h
	ret
	
;Change the keyboard
changing_Memory_Of_Input :
	mov BX, 1000h
	mov DS, BX
	mov CX, 26						; Go over all ASCII characters
	alphabet_Change :
		mov AL, [BX]
		mov AH,	[BX + 27]
		push BX
		call find_And_Update_Row_And_Column
		pop BX
		inc BX
	loop alphabet_Change
	mov BX, 2000h
	mov DS, BX
	ret
	
;input AL = Old ASCII, AH = New ASCII
find_And_Update_Row_And_Column :
	mov BX, 800h					; Move to relevant memory
	mov DS, BX
	find_old_ascii:
		cmp [BX], AL
			je change
		add BX, 4
	jmp find_old_ascii
	change:
	mov [BX + 3], AH
	mov BX, 1000h					; Go back to relevant memory
	mov DS, BX
	ret
;=============================VARIABLES==============================
row_start db 26
column_start db 50
menu db 'MENU'
placements db 08h, 0ah, 0ch, 0eh, 10h, 12h
strings db 'Clear Changes', 'Change a Button', 'Create Keyboard Settings', 'Set My Settings', 'Print', 'Exit'
length_string db 13, 15, 24, 15, 5, 4
;====================================================================
times 2*8*63*512 - ($-$$) db 0     	; We needed create HD or floppy drive   
									; 2=cylinders, 8=heads, 64=sectors, 512=bytes/sector 
									