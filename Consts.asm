;Author:Quantum Team
;Date:21-11-2016
;Global constants for our game
;----------------------------------------------

;Main constants
WindowWidth                 EQU     80
WindowHeight                EQU     25
CurrentPage                 EQU     0
MaxUserNameSize             EQU     16

;Keys codes
ESC_ScanCode                EQU     01H
ESC_AsciiCode               EQU     1BH
Enter_ScanCode              EQU     1CH
Enter_AsciiCode             EQU     0DH
Back_ScanCode               EQU     0EH
Back_AsciiCode              EQU     08H
F1_ScanCode                 EQU     3BH
F2_ScanCode                 EQU     3CH
F3_ScanCode                 EQU     3DH
F4_ScanCode                 EQU     3EH
UP_ScanCode                 EQU     48H
UP_AsciiCode                EQU     2H      ;Application defined
DOWN_ScanCode               EQU     50H
DOWN_AsciiCode              EQU     1H      ;Application defined
W_ScanCode                  EQU     11H
S_ScanCode                  EQU     1FH

;Application key codes
KeyGameLevel                EQU     10000000B
KeyScore1                   EQU     10010000B
KeyScore2                   EQU     10100000B
KeyPaddleY1                 EQU     10110000B
KeyPaddleY2                 EQU     11000000B
KeyBallPosY                 EQU     11010000B
KeyBallPosLestX             EQU     11100000B
KeyBallPosMostX             EQU     11110000B