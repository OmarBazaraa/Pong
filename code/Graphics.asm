;Author:Omar Bazaraa
;Date:29-10-2016
;Macros for some graphics interrupts
;----------------------------------------------

;Change video mode: 
;03H for 80x25 text mode (16 colors, 8 pages)
;04H for 320x200 graphics mode (4 colors)
;06H for 640x200 graphics mode (2 colors)
;13H for 320x200 graphics mode (256 colors)
SetVideoMode MACRO Mode
    MOV AH, 00H
    MOV AL, Mode
    INT 10H
ENDM SetVideoMode

;Set cursor position to (X, Y) in PageNum
SetCursorPos MACRO X, Y, PageNum
    MOV AH, 02H
    MOV BH, PageNum
    MOV DL, X
    MOV DH, Y
    INT 10H
ENDM SetCursorPos

;Get cursor position in PageNum: DL=X, DH=Y
GetCursorPos MACRO PageNum
    MOV AH, 03H
    MOV BH, PageNum
    INT 10H
ENDM GetCursorPos

;Scroll up or clear screen from (x1, y1) to (x2, y2)
ScrollUp MACRO X1, Y1, X2, Y2, LinesCount
    MOV AH, 06H
    MOV AL, LinesCount
    MOV BH, 07H
    MOV CL, X1
    MOV CH, Y1
    MOV DL, X2
    MOV DH, Y2
    INT 10H
ENDM ScrollUp

;Clear portion of screen from (x1, y1) to (x2, y2)
ClearScreen MACRO X1, Y1, X2, Y2
    MOV AX, 0600H
    MOV BH, 07H
    MOV CL, X1
    MOV CH, Y1
    MOV DL, X2
    MOV DH, Y2
    INT 10H
ENDM ClearScreen

;Display a character number of times with a certain color
PrintColoredChar MACRO Char, Color, Cnt, PageNum
    MOV AH, 09H         ;Display
    MOV BH, PageNum     ;Page 0
    MOV AL, Char        ;Character to display
    MOV BL, Color       ;Color(back:fore)
    MOV CX, Cnt         ;Number of times
    INT 10H
ENDM PrintColoredChar

;Draw pixel in (X, Y) position with certain color
DrawPixel MACRO X, Y, Color
    MOV AH, 0CH
    MOV AL, Color
    MOV CX, X
    MOV DX, Y
    INT 10H
ENDM DrawPixel

;Draw a vertical line starting from (X, Y) with a certain length and width
DrawLine MACRO StartX, StartY, VerticalLength, HorizontalWidth, Char, Color, PageNum
    LOCAL Back
    
    MOV SI, 0
    
    Back:
        MOV CX, SI
        ADD CL, StartY
        SetCursorPos StartX, CL, PageNum
        PrintColoredChar Char, Color, HorizontalWidth, PageNum
        
        INC SI
        CMP SI, VerticalLength
        JB Back
ENDM DrawHorizontalLine