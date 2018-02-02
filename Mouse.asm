;Author:Omar Bazaraa
;Date:29-10-2016
;Macros for some mouse interrupts
;----------------------------------------------

;Check for mouse connection: AX=mouse_status (FFFF if mouse connected)
CheckMouseConn MACRO
    MOV AX, 00H
    INT 33H
ENDM CheckMouseConn

;Show mouse cursor
ShowMouse MACRO
    MOV AX, 01H
    INT 33H
ENDM ShowMouse

;Hide mouse cursor
HideMouse MACRO
    MOV AX, 02H
    INT 33H
ENDM HideMouse

;Get mouse position: CX=row_pos, DX=col_pos, BX=button_status
GetMousePos MACRO
    MOV AX, 03H
    INT 33H
ENDM GetMousePos

;Set mouse position to (row_pos, col_pos)
SetMousePos MACRO row_pos, col_pos
    MOV AX, 04H
    MOV CX, row_pos
    MOV DX, col_pos
    INT 33H
ENDM SetMousePos