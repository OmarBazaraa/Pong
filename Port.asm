;Author:Omar Bazaraa
;Date:21-11-2016
;Macros for chat module
;----------------------------------------------

;Serial Port address location
COMAddress EQU 3F8H

;Initializes serial port with a certian configuration
InitSerialPort MACRO
    ;Set divisor latch access bit
    MOV DX, COMAddress+3    ;Line control register
    MOV AL, 10000000b
    OUT DX, AL

    ;Set the least significant byte of the Baud rate divisor latch register
    MOV DX, COMAddress
    MOV AL, 0CH
    OUT DX, AL

    ;Set the most significant byte of the Baud rate divisor latch register
    MOV DX, COMAddress+1
    MOV AL, 0
    OUT DX, AL

    ;Set serial port configurations
    MOV DX, COMAddress+3    ;Line Control Register
    MOV AL, 00011011B
    ;0:     Access to receiver and transmitter buffers
    ;0:     Set break disabled
    ;011:   Even parity
    ;0:     One stop bit
    ;11:    8-bit word length
    OUT DX, AL
ENDM InitSerialPort

;Send character through serial port
SendChar MACRO MyChar
    LOCAL Send
    Send:
    MOV DX, COMAddress+5    ;Line Status Register
    IN AL, DX
    AND AL, 00100000B       ;Check transmitter holding register status: 1 ready, 0 otherwise
    JZ Send                 ;Transmitter is not ready
    MOV DX, COMAddress
    MOV AL, MyChar
    OUT DX, AL
ENDM SendChar

;Receive a character from the serial port into AL
ReceiveChar MACRO
    LOCAL Return
    MOV AL, 0
    MOV DX, COMAddress+5    ;Line Status Register
    IN AL, DX
    AND AL, 00000001B       ;Check for data ready
    JZ Return               ;No character received
    MOV DX, COMAddress      ;Receive data register
    IN AL, DX
    Return:
ENDM ReadPortChar
