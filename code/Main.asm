;Author:Quantum Team
;Date:08-12-2016
;Main module that controls navigation between various game functionalities
;----------------------------------------------
;
;Macros
;
;Process a given user input. Called from within a procedure
ProcessInput MACRO Char, Player
    LOCAL CheckChat, StartChatting, CheckGame, ChooseGameLevel, StartPlaying, CheckEscape, Quit, Reset, Return

    ;Check if Chat (F1) is pressed
    CheckChat:
    CMP Char, F1_ScanCode
    JNE CheckGame
    
    MOV AL, ChatInvitation
    OR  AL, Player
    CMP AL, 3               ;Only equals 3 when the other player accept the invitation
    JE StartChatting
    
    ;Send invitation
    MOV ChatInvitation, Player
    CALL PrintNavigationScreen
    RET
    
    ;Accept invitation
    StartChatting:
    CALL StartChat
    MOV ChatInvitation, 0
    CALL PrintNavigationScreen
    RET
    ;==================================
    
    ;Check if Game (F2) is pressed
    CheckGame:
    CMP Char, F2_ScanCode
    JNE CheckEscape
    
    MOV AL, GameInvitation
    OR  AL, Player
    CMP AL, 3               ;Only equals 3 when the other player accept the invitation
    JE ChooseGameLevel
    
    ;Send invitation
    MOV GameInvitation, Player
    CALL PrintNavigationScreen
    RET
    
    ;Accept invitation
    ChooseGameLevel:
    MOV AL, Player
    CMP AL, 2
    JNE StartPlaying
    MOV IsMainPlayer, 1
    CALL GetGameLevel
    
    StartPlaying:
    CALL PlayGame
    MOV GameInvitation, 0
    MOV IsMainPlayer, 0
    MOV GameLevel, '?'
    CALL PrintNavigationScreen
    RET
    ;==================================
    
    ;Check if Quit (ESC) is pressed
    CheckEscape:
    CMP Char, ESC_ScanCode
    JNE Return
    
    MOV AL, Player
    CMP AL, 1
    JNE Reset
    
    Quit:
    ;Back to the system
    MOV AX, 4C00H
    INT 21H
    RET
        
    Reset:
    MOV ChatInvitation, 0
    MOV GameInvitation, 0
    MOV MainReceivedChar, 0
    CALL WaitOtherPlayer
    CALL PrintNavigationScreen
    ;==================================
    
    Return:
ENDM ProcessInput
;===============================================================

;Includes
INCLUDE Pong\Consts.asm
INCLUDE Pong\Graphics.asm
INCLUDE Pong\Keyboard.asm
INCLUDE Pong\Port.asm
INCLUDE Pong\Mouse.asm

;Public variables and procedures
PUBLIC GameLevel
PUBLIC IsMainPlayer
PUBLIC UserName1Size, UserName1
PUBLIC UserName2Size, UserName2

;External variables and procedures
EXTRN StartChat:FAR
EXTRN PlayGame:FAR
;===============================================================

.MODEL SMALL
.STACK 64
.DATA
;Main screen variables
LogoStartX                  EQU     1
LogoStartY                  EQU     1
LogoWidth                   EQU     50
LogoHeight                  EQU     5
LogoColor                   EQU     03FH
NotiBarStartX               EQU     0
NotiBarStartY               EQU     WindowHeight-NotiBarHeight
NotiBarWidth                EQU     WindowWidth-NotiBarStartX*2
NotiBarHeight               EQU     4
NotiBarBorderWidth          EQU     1
NotiBarColor                EQU     0FH
NotiBarChar                 DB      '-'
MsgMarginX                  EQU     LogoStartX
MsgMarginY                  EQU     LogoStartY+LogoHeight+1

;Program messages and strings
GameTitle                   DB      'Pong Game$'
GameTitleSize               EQU     ($-GameTitle)
NameEntryMsg                DB      'Please enter your name: $'
NameEntryConstrainsMsg      DB      'Max length 15 characters and must starts with a letter$'
ContinueMsg                 DB      'Press any key to continue...$'
WaitingPlayerMsg            DB      'Waiting other player to connect...$'
WelcomeMsg                  DB      'Welcome $'
ConnectedWithMsg            DB      'You are connected with $'
NavigationMsg               DB      'Please choose an option: $'
StartChattingMsg            DB      '[ F1] to start chatting$'
StartGameMsg                DB      '[ F2] to start Pong Game$'
EndProgMsg                  DB      '[ESC] to exit$'
GameLevelMsg                DB      'Please choose a level for the game: $'
Level1Msg                   DB      '[1] for level 1$'
Level2Msg                   DB      '[2] for level 2$'
ChatInvitation              DB      0   ;0-No invitations, 1-invitation sent, 2-invitation-received
ChatInvitationSentMsg       DB      'You sent a chat invitation to $'
ChatInvitationReceivedMsg   DB      'Press F1 to accept chat invitation from $'
GameInvitation              DB      0   ;0-No invitations, 1-invitation sent, 2-invitation-received
GameInvitationSentMsg       DB      'You sent a game invitation to $'
GameInvitationReceivedMsg   DB      'Press F2 to accept game invitation from $'

;Game variables
GameLevel                   DB      '?'
IsMainPlayer                DB      0
UserName1Size               DB      MaxUserNameSize, ?
UserName1                   DB      MaxUserNameSize dup('$'), '$'
UserName2Size               DB      MaxUserNameSize, ?
UserName2                   DB      MaxUserNameSize dup('$'), '$'

;Serial communication variables
MainSentChar                DB      ?
MainReceivedChar            DB      ?
;===============================================================

.CODE
;Main procedure that control the game navigations and functionalities
MAIN PROC FAR
    MOV AX, @DATA
    MOV DS, AX
    
    ;Initialize the serial port communication
    InitSerialPort
    
    ;Ask for username and exchange it with the other player
    CALL GetUserName
    CALL WaitOtherPlayer
    CALL PrintNavigationScreen
    
    Main_Loop:
    
    ;Get primary user input and send it to secondary user
    Main_Send:
    GetKeyPressAndFlush
    JZ Main_Receive                 ;Skip processing user input if no key is pressed
    MOV MainSentChar, AH
    SendChar MainSentChar
    CALL ProcessPrimaryInput
    
    ;Get secondary user input
    Main_Receive:
    ReceiveChar
    JZ Main_Loop                    ;Skip processing user input if no key is received
    MOV MainReceivedChar, AL
    CALL ProcessSecondaryInput
    
    ;Back to main loop
    JMP Main_Loop

MAIN ENDP
;===============================================================

;Asks the user for his name and store it
GetUserName PROC
    UserName_Back:

    ;Draw the game logo
    CALL DrawGameLogo
    
    ;Print messages
    SetCursorPos MsgMarginX, MsgMarginY+1, CurrentPage
    PrintString NameEntryConstrainsMsg
    SetCursorPos MsgMarginX, MsgMarginY, CurrentPage
    PrintString NameEntryMsg
    
    ;Clear username
    MOV BX, 0
    UserName_Clear:
    MOV UserName1[BX], '$'
    INC BX
    CMP BX, MaxUserNameSize
    JLE UserName_Clear
    
    ;Wait for user input
    ReadString UserName1Size
    
    ;Check if first character doesn't start with a letter
    CMP UserName1[0], 'A'
    JB  UserName_Back
    CMP UserName1[0], 'Z'
    JBE UserName_Return

    CMP UserName1[0], 'a'
    JB  UserName_Back
    CMP UserName1[0], 'z'
    JA  UserName_Back
    
    UserName_Return:
    
    ;Wait for any key to continue
    SetCursorPos MsgMarginX, MsgMarginY+3, CurrentPage
    PrintString ContinueMsg
    WaitKeyPress
    RET
GetUserName ENDP
;===============================================================

;Waits for the other player to connect and exchanges usernames
WaitOtherPlayer PROC
    ;Draw the game logo
    CALL DrawGameLogo
    
    ;Print waiting message
    SetCursorPos MsgMarginX, MsgMarginY, CurrentPage
    PrintString WaitingPlayerMsg
    
    ;Hide the cursor some where in the screen
    SetCursorPos WindowWidth, WindowHeight, 0
    
    MOV BX, 1
    
    UserName_Send:
    ;Send a letter of username
    MOV CL, UserName1Size[BX]
    SendChar CL
    
    ;Receive a letter from other player
    UserName_SendNotReceived:
    
    ;Check if ESC is pressed to quit the program
    GetKeyPressAndFlush
    CMP AL, ESC_AsciiCode
    JNE UserName_ContinueReceive
    MOV AX, 4C00H
    INT 21H         ;Back to the system
    
    UserName_ContinueReceive:
    ReceiveChar
    JZ UserName_SendNotReceived
    
    MOV UserName2Size[BX], AL
    INC BX
    CMP BX, MaxUserNameSize
    JLE UserName_Send
    
    EmptyKeyQueue
    RET
WaitOtherPlayer ENDP
;===============================================================

;Asks the user to choose the game level
GetGameLevel PROC
    ;Draw the game logo
    CALL DrawGameLogo
    
    ;Print messages
    SetCursorPos MsgMarginX, MsgMarginY, CurrentPage
    PrintString GameLevelMsg
    SetCursorPos MsgMarginX, MsgMarginY+2, CurrentPage
    PrintString Level1Msg
    SetCursorPos MsgMarginX, MsgMarginY+3, CurrentPage
    PrintString Level2Msg
    
    ;Hide the cursor some where in the screen
    SetCursorPos WindowWidth, WindowHeight, 0
    
    GameLevel_Back:
    
    ;Wait for user choice
    WaitKeyPress

    ;Detect user input
    CMP AL, '1'
    JL  GameLevel_Back
    CMP AL, '2'
    JA  GameLevel_Back
    
    MOV GameLevel, AL
    RET
GetGameLevel ENDP
;===============================================================

;Process primary user input
ProcessPrimaryInput PROC
    ProcessInput MainSentChar, 1
    RET
ProcessPrimaryInput ENDP
;===============================================================

;Process secondary user input
ProcessSecondaryInput PROC
    ProcessInput MainReceivedChar, 2
    RET
ProcessSecondaryInput ENDP
;===============================================================

;Clears the entire screen and draws the logo of the game
DrawGameLogo PROC
    ;Clear the entire screen
    ClearScreen 0, 0, WindowWidth, WindowHeight
    ;Color a portion of the screen for the game logo
    DrawLine LogoStartX, LogoStartY, LogoHeight, LogoWidth, ' ', LogoColor, CurrentPage
    ;Center the cursor in the logo area
    SetCursorPos LogoStartX+(LogoWidth-GameTitleSize)/2, LogoStartY+LogoHeight/2, CurrentPage
    ;Print game title in the center
    PrintString GameTitle
    RET
DrawGameLogo ENDP
;===============================================================

;Initializes the main screen with different navigation options
PrintNavigationScreen PROC
    ;Draw the game logo
    CALL DrawGameLogo
    
    ;Draw notification bar
    CALL DrawNotiBar
    
    ;Print players name
    SetCursorPos MsgMarginX, MsgMarginY+0, CurrentPage
    PrintString WelcomeMsg
    PrintString UserName1
    SetCursorPos MsgMarginX, MsgMarginY+1, CurrentPage
    PrintString ConnectedWithMsg
    PrintString UserName2
    
    ;Print navigation messages
    SetCursorPos MsgMarginX, MsgMarginY+4, CurrentPage
    PrintString NavigationMsg
    SetCursorPos MsgMarginX, MsgMarginY+6, CurrentPage
    PrintString StartChattingMsg
    SetCursorPos MsgMarginX, MsgMarginY+7, CurrentPage
    PrintString StartGameMsg
    SetCursorPos MsgMarginX, MsgMarginY+8, CurrentPage
    PrintString EndProgMsg
    
    ;Hide the cursor some where in the screen
    SetCursorPos WindowWidth, WindowHeight, 0
    
    RET
PrintNavigationScreen ENDP
;===============================================================

;Draws notification bar
DrawNotiBar PROC
    ;Draw begin separator
    DrawLine NotiBarStartX, NotiBarStartY, NotiBarBorderWidth, NotiBarWidth, NotiBarChar, NotiBarColor, CurrentPage
    ;Draw end separator
    DrawLine NotiBarStartX, NotiBarStartY+NotiBarHeight-NotiBarBorderWidth, NotiBarBorderWidth, NotiBarWidth, NotiBarChar, NotiBarColor, CurrentPage
    
    ;
    ;Write notification messages
    ;
    
    ;Chat invitation sent message
    NotificationChatSent:
    CMP ChatInvitation, 1
    JNE NotificationChatReceived
    SetCursorPos MsgMarginX, NotiBarStartY+NotiBarBorderWidth, CurrentPage
    PrintString ChatInvitationSentMsg
    PrintString UserName2
    ;==================================
    
    ;Chat invitation received message
    NotificationChatReceived:
    CMP ChatInvitation, 2
    JNE NotificationGameSent
    SetCursorPos MsgMarginX, NotiBarStartY+NotiBarBorderWidth, CurrentPage
    PrintString ChatInvitationReceivedMsg
    PrintString UserName2
    ;==================================
    
    ;Game invitation sent message
    NotificationGameSent:
    CMP GameInvitation, 1
    JNE NotificationGameReceived
    SetCursorPos MsgMarginX, NotiBarStartY+NotiBarBorderWidth+1, CurrentPage
    PrintString GameInvitationSentMsg
    PrintString UserName2
    ;==================================
    
    ;Game invitation received message
    NotificationGameReceived:
    CMP GameInvitation, 2
    JNE NotificationReturn
    SetCursorPos MsgMarginX, NotiBarStartY+NotiBarBorderWidth+1, CurrentPage
    PrintString GameInvitationReceivedMsg
    PrintString UserName2
    ;==================================
    
    NotificationReturn:
    RET
DrawNotiBar ENDP
;===============================================================

END MAIN