;Author:Omar Bazaraa
;Date:29-10-2016
;Macros for some keyboard interrupts
;----------------------------------------------

;Wait key press: AH=scan_code, AL=ASCII_code
WaitKeyPress MACRO
    MOV AH, 00H
    INT 16H
ENDM WaitKeyPress

;Get key press: AH=scan_code, AL=ASCII_code
GetKeyPress MACRO
    MOV AH, 01H
    INT 16H
ENDM GetKeyPress

;Get key press and flush it: AH=scan_code, AL=ASCII_code
GetKeyPressAndFlush MACRO
    LOCAL KeyNotPressed
    GetKeyPress
    JZ KeyNotPressed
    WaitKeyPress
    KeyNotPressed:
ENDM GetKeyPressAndFlush

;Empty the key queue
EmptyKeyQueue MACRO
    LOCAL Back, Return
    Back:
    GetKeyPress
    JZ Return
    WaitKeyPress
    JMP Back
    Return:
ENDM EmptyKeyQueue

;Display one character
PrintChar MACRO MyChar
    MOV AH, 02H
    MOV DL, MyChar
    INT 21H
ENDM PrintChar

;Read one character without echo in AL
ReadChar MACRO MyChar
    MOV AH, 07H
    INT 21H
    MOV MyChar, AL
ENDM ReadChar

;Display string untill '$' character
PrintString MACRO MyStr
    MOV AH, 09H
    MOV DX, OFFSET MyStr
    INT 21H
ENDM PrintString

;Read string from keyboard
ReadString MACRO MyStr
    MOV AH, 0AH
    MOV DX, OFFSET MyStr
    INT 21H
ENDM ReadString
