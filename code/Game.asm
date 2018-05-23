;Author:Quantum Team
;Date:09-12-2016
;Pong Game module containing all game drawing and logic
;----------------------------------------------

;
;Macros
;
;Processes main user input. Called from within a procedure
ProcessMainInput MACRO Char, Player
    LOCAL CheckEscape, CheckServe, Return
    
    ;Check if Quit (ESC) is pressed
    CheckEscape:
    CMP Char, ESC_AsciiCode
    JNE CheckServe
    MOV IsGameEnded, 1
    RET
    ;==================================
    
    ;Check if ball serve is needed
    CheckServe:
    CMP ServeTurn, Player
    JNE Return
    MOV Char, 0
    MOV ServeTurn, 0
    CALL GetRandomBallDirection
    RET
    ;==================================
    
    Return:
ENDM ProcessMainInput
;===============================================================

;Process game user input. Called from within a procedure
ProcessGameInput MACRO Char, PaddleX, PaddleY, PaddleKey
    LOCAL CheckUp, CheckDown, Return
    
    ;Check if UP is pressed
    CheckUp:
    CMP Char, UP_AsciiCode
    JNE CheckDown
    MovePaddleUp PaddleX, PaddleY
    SendAppVariables PaddleKey, PaddleY
    RET
    ;==================================
    ;Check if DOWN is pressed
    CheckDown:
    CMP Char, DOWN_AsciiCode
    JNE Return
    MovePaddleDown PaddleX, PaddleY
    SendAppVariables PaddleKey, PaddleY
    RET
    ;==================================
    
    Return:
    RET
ENDM ProcessChatInput
;===============================================================

;Process chat user input. Called from within a procedure
ProcessChatInput MACRO Char, X, Y, OffsetY
    LOCAL CheckEnter, CheckBackspace, CheckPrintable, AdjustCursorPos, Scroll, Return

    ;Check if Enter is pressed
    CheckEnter:
    CMP Char, Enter_AsciiCode
    JNE CheckBackspace
    MOV X, ChatMsgMargin
    INC Y
    JMP Scroll
    ;==================================
    
    ;Check if Backspace is pressed
    CheckBackspace:
    CMP Char, Back_AsciiCode
    JNE CheckPrintable
    CMP X, ChatMsgMargin
    JBE CheckPrintable
    MOV Char, ' '
    DEC X
    SetCursorPos X, Y, CurrentPage
    PrintChar Char
    RET
    ;==================================
    
    ;Check if printable character is pressed
    CheckPrintable:
    CMP Char, ' '   ;Compare with lowest printable ascii value
    JB Return
    CMP Char, '~'   ;Compare with highest printable ascii value
    JA Return
    
    ;Print char
    SetCursorPos X, Y, CurrentPage
    PrintChar Char
    ;==================================
    
    ;Adjust new cursor position after printing the character
    AdjustCursorPos:
    INC X
    CMP X, ChatAreaWidth-ChatMargin
    JL Return
    MOV X, ChatMsgMargin
    INC Y
    ;==================================
    
    ;Scroll chat area one step up if chat area is full
    Scroll:
    CMP Y, ChatAreaHeight+OffsetY-1
    JBE Return
    DEC Y
    ScrollUp ChatMsgMargin, OffsetY, ChatAreaWidth-ChatMargin, ChatAreaHeight+OffsetY-1, 1
    ;==================================
    
    Return:
ENDM ProcessChatInput
;===============================================================

;Sends application defined variables by key and value
SendAppVariables MACRO Key, Value
    MOV DL, Key
    OR  DL, Value
    MOV GameSentChar, DL
    SendChar GameSentChar
ENDM SendAppVariables
;===============================================================

;Pause the app until a specified key is received or ESC is pressed
ReceiveAppVariables MACRO Key
    LOCAL WaitLabel, WaitLabel_Contiune, Return

    CMP IsGameEnded, 1
    JE  Return
    
    WaitLabel:
    
    ;Breaking condition to avoid infinite loop if connection lost
    GetKeyPressAndFlush
    CMP AL, ESC_AsciiCode
    JNE WaitLabel_Contiune
    MOV IsGameEnded, 1
    MOV GameSentChar, AL
    SendChar GameSentChar
    JMP Return
    
    WaitLabel_Contiune:
    ReceiveChar
    CMP AL, Key
    JNE WaitLabel
    
    Return:
ENDM ReceiveAppVariables
;===============================================================

;Draws pong game paddle
DrawPaddle MACRO X, Y, Color
    DrawLine X, Y, PaddleHeight, PaddleWidth, PaddleChar, Color, CurrentPage
ENDM DrawPaddle
;===============================================================

;Draws pong ball
DrawBall MACRO Color
    SetCursorPos BallPositionX, BallPositionY, CurrentPage
    PrintColoredChar BallChar, Color, 1, CurrentPage
ENDM DrawBall
;===============================================================

;Moves a given paddle one step up
MovePaddleUp MACRO StartX, StartY
    LOCAL Return

    ;Check if the paddle is already at the top
    CMP StartY, ArenaStartY+ArenaBorderWidth
    JE Return

    ;Clear the lower paddle character
    MOV CL, StartY
    ADD CL, PaddleHeight-1
    SetCursorPos StartX, CL, CurrentPage
    PrintColoredChar PaddleChar, ArenaBackColor, PaddleWidth, CurrentPage

    ;Draw the upper paddle character
    MOV CL, StartY
    DEC CL
    MOV StartY, CL
    SetCursorPos StartX, CL, CurrentPage
    PrintColoredChar PaddleChar, PaddleColor, PaddleWidth, CurrentPage

    Return:
ENDM MovePaddleUp
;===============================================================

;Moves a given paddle one step down
MovePaddleDown MACRO StartX, StartY
    LOCAL Return

    ;Check if the paddle is already at the bottom
    CMP StartY, ArenaEndY-PaddleHeight
    JE Return

    ;Clear upper paddle character
    MOV CL, StartY
    SetCursorPos StartX, CL, CurrentPage
    PrintColoredChar PaddleChar, ArenaBackColor, PaddleWidth, CurrentPage

    ;Draw lower paddle character
    MOV CL, StartY
    INC CL
    MOV StartY, CL
    ADD CL, PaddleHeight-1
    SetCursorPos StartX, CL, CurrentPage
    PrintColoredChar PaddleChar, PaddleColor, PaddleWidth, CurrentPage

    Return:
ENDM MovePaddleDown
;===============================================================

;Control ball movement and check if a player scores a point
CheckForValidityAndMove MACRO PaddleStartX, PaddleStartY, PlayerIndex
    LOCAL CheckForY, PlayerLose, NotOnPaddle, CheckBelowArena, ValidPosition, Reflected, InvalidPosition
    LOCAL UpperThird, LowerThird, NegateX
    
    MOV AL, BallPositionX
    ADD AL, BallVelocityX       ;AL=BallX+VelocityX
    MOV AH, BallPositionY
    ADD AH, CurrentVelocityY    ;AL=BallX+VelocityY
    
    CMP AL, PaddleStartX
    JNE NotOnPaddle
    
    CheckForY:
    MOV BH, BallPositionY
    CMP BH, PaddleStartY
    JL PlayerLose
    
    MOV CH, PaddleStartY
    ADD CH, PaddleHeight
    DEC CH
    
    CMP BH, CH
    JG PlayerLose

    UpperThird:
    MOV CH, PaddleStartY
    ADD CH, PaddleHeight/3
    CMP BH, CH
    JGE LowerThird
    
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, -1
    MOV CurrentVelocityY, 0
    JMP NegateX
    
    LowerThird:
    ADD CH, PaddleHeight/3
    CMP BH, CH
    JL NegateX
    
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, 1
    MOV CurrentVelocityY, 0
    
    NegateX:
    NEG BallVelocityX
    JMP Reflected
    
    PlayerLose:
    MOV LoserIdx, PlayerIndex
    JMP InvalidPosition
    
    NotOnPaddle:
    CMP AH, ArenaStartY+ArenaBorderWidth
    JGE CheckBelowArena         ;note there was a zew here
    
    NEG BallVelocityYEven
    NEG BallVelocityYOdd
    NEG CurrentVelocityY
    JMP Reflected
    
    CheckBelowArena:
    CMP AH, ArenaStartY+ArenaHeight-ArenaBorderWidth
    JLE ValidPosition
    
    NEG BallVelocityYEven
    NEG BallVelocityYOdd
    NEG CurrentVelocityY
    JMP Reflected

    ValidPosition:
    MOV BallPositionX, AL
    MOV BallPositionY, AH
    
    Reflected:
    InvalidPosition:
ENDM CheckForValidityAndMove
;===============================================================

;Includes
INCLUDE Pong\Consts.asm
INCLUDE Pong\Graphics.asm
INCLUDE Pong\Keyboard.asm
INCLUDE Pong\Port.asm
INCLUDE Pong\Mouse.asm

;Public variables and procedures
PUBLIC PlayGame

;External variables and procedures
EXTRN GameLevel:BYTE
EXTRN IsMainPlayer:BYTE
EXTRN UserName1:BYTE
EXTRN UserName1Size:BYTE
EXTRN UserName2:BYTE
EXTRN UserName2Size:BYTE
;===============================================================

.MODEL SMALL
.DATA
;Arena variables
ArenaStartX                 EQU     0
ArenaStartY                 EQU     0
ArenaEndY                   EQU     ArenaStartY+ArenaHeight-ArenaBorderWidth+1
ArenaWidth                  EQU     WindowWidth-ArenaStartX*2
ArenaHeight                 EQU     15
ArenaBackColor              EQU     00H
ArenaBorderWidth            EQU     1
ArenaBorderColor            EQU     0FH
ArenaBorderChar             EQU     '-'
ArenaScoreHeight            EQU     2
ArenaScoreEndY              EQU     ArenaEndY+ArenaScoreHeight

;Paddle variables
Paddle1StartX               EQU     ArenaStartX+1
Paddle1StartY               DB      ArenaHeight/2-PaddleHeight/2
Paddle2StartX               EQU     ArenaStartX+ArenaWidth-PaddleWidth-1
Paddle2StartY               DB      ArenaHeight/2-PaddleHeight/2
PaddleHeight                EQU     3
PaddleWidth                 EQU     1
PaddleColor                 EQU     0FFH
PaddleChar                  EQU     ' '

;Ball variables
BallPositionX               DB      ArenaWidth/2+ArenaStartX
BallPositionY               DB      ArenaHeight/2+ArenaStartY
BallVelocityX               DB      1
BallVelocityYEven           DB      1
BallVelocityYOdd            DB      1
CurrentVelocityY            DB      1
BallColor                   EQU     00FH
BallChar                    EQU     'o'

;Score variables
Score1                      DB      '0'
Score2                      DB      '0'
MaxScoreValue               EQU     '5'
Score1StartX                EQU     ArenaStartX+1
Score2StartX                EQU     ArenaWidth-Score1StartX*2-MaxUserNameSize-2
ScoreStartY                 EQU     ArenaScoreEndY-1
GameLevelLabel              DB      'Level : $'
GameLevelLabelSize          EQU     ($-GameLevelLabel+1)
GameLevelStartX             EQU     (ArenaWidth-GameLevelLabelSize)/2

;Inline chat variables
ChatStartX                  EQU     0
ChatStartY                  EQU     ArenaScoreEndY+ArenaBorderWidth
ChatAreaWidth               EQU     WindowWidth
ChatAreaHeight              EQU     (InfoBarStartY-ChatStartY)/2
ChatMargin                  EQU     ChatStartX+1
ChatMsgMargin               EQU     ChatMargin+MaxUserNameSize+2
ChatLineColor               EQU     0FH
ChatLineChar                DB      '-'
User1CursorX                DB      ChatMsgMargin
User1CursorY                DB      ChatStartY
User2CursorX                DB      ChatMsgMargin
User2CursorY                DB      ChatStartY+ChatAreaHeight

;Info bar variables
InfoBarStartX               EQU     0
InfoBarStartY               EQU     WindowHeight-3
WaitingGameLevelMsg         DB      'Waiting main player to select the level of the game...$'
EndGameMsg                  DB      'Press ESC to end the game...$'
GameOverMsg                 DB      'Game Over! Quitting...$'

;Game variables
GameSentChar                DB      ?
GameReceivedChar            DB      ?
IsGameEnded                 DB      0
LoserIdx                    DB      0
ServeTurn                   DB      1
OuterWaitLoop               DW      01FFH
InnerWaitLoop               DW      0FH
OuterWaitLoopInit           DW      01FFH
InnerWaitLoopInit           DW      0FH
OuterWaitLoopInit1          EQU     01FFH   ;Initial value for wait loop at game level=1
InnerWaitLoopInit1          EQU     0FH
OuterWaitLoopInit2          EQU     0FFH    ;Initial value for wait loop at game level=2
InnerWaitLoopInit2          EQU     0FH
;===============================================================

.CODE
;Start playing pong game
PlayGame PROC FAR
    ;Initialize game variables
    CALL InitGame
    
    GameLoop:
    
    ;Check if game ended
    CMP IsGameEnded, 1
    JNE GameLoop_Continue
    CALL DrawEndScreen
    RET
    
    GameLoop_Continue:
    
    ;Set the cursor to the primary user chat area
    SetCursorPos User1CursorX, User1CursorY, CurrentPage
    
    ;Get user inputs and process them
    CALL ControlInputs
    
    CMP IsMainPlayer, 1
    JNE GameLoop
    
    ;Waiting loop
    DEC InnerWaitLoop
    CMP InnerWaitLoop, 0
    JNE GameLoop
    MOV AX, InnerWaitLoopInit
    MOV InnerWaitLoop, AX
    DEC OuterWaitLoop
    CMP OuterWaitLoop, 0
    JNE GameLoop
    MOV AX, OuterWaitLoopInit
    MOV OuterWaitLoop, AX
    
    ;Update ball velocity vector and move it one step
    MOV BH, BallVelocityYEven
    ADD BH, BallVelocityYOdd
    SUB BH, CurrentVelocityY
    MOV CurrentVelocityY, BH    ;CurrentVelocityY = BallVelocityYEven + BallVelocityYOdd - CurrentVelocityY 
    CALL MoveBall
    
    ;Check if any player scores
    CMP LoserIdx, 0
    JLE GameLoop
    
    CALL UpdateScore
    CALL ResetGame
    JMP GameLoop

    RET
PlayGame ENDP
;===============================================================

;Controls game events and keys detection
ControlInputs PROC
    ;Clear chars
    MOV GameSentChar, 0
    MOV GameReceivedChar, 0

    ;Get primary user input and send it to secondary user
    GameControl_Send:
    GetKeyPressAndFlush
    JZ GameControl_Receive          ;Skip processing user input if no key is pressed
    CALL NormalizeCodes             ;Replaces UP/DOWN scancode with an application defined ascii code
    MOV GameSentChar, AL
    SendChar GameSentChar
    CALL ProcessPrimaryMainInput
    CALL ProcessPrimaryGameInput
    CALL ProcessPrimaryChatInput
    
    ;Get secondary user input
    GameControl_Receive:
    ReceiveChar
    JZ GameControl_Return           ;Skip processing user input if no key is received
    MOV GameReceivedChar, AL
    CALL ProcessSecondaryMainInput
    CALL ProcessSecondaryGameInput
    CALL ProcessSecondaryChatInput
    CALL ReceiveGameState
    
    GameControl_Return:
    RET
ControlInputs ENDP
;===============================================================

;Replaces UP/DOWN scancode with an application defined ascii code
NormalizeCodes PROC
    GameControl_UP:
    CMP AH, UP_ScanCode
    JNE GameControl_DOWN
    MOV AL, UP_AsciiCode
    
    GameControl_DOWN:
    CMP AH, DOWN_ScanCode
    JNE GameControl_Continue
    MOV AL, DOWN_AsciiCode
    
    GameControl_Continue:
    RET
NormalizeCodes ENDP
;===============================================================

;Receives game states
ReceiveGameState PROC
    CMP IsMainPlayer, 1
    JNE Process0
    RET
    Process0:
    
    ;AH=key, AL=value
    MOV AH, GameReceivedChar
    AND AH, 0F0H
    MOV AL, GameReceivedChar
    AND AL, 00FH
    
    ;Receive ball least significant x position
    GameState_BallLeastX:
    CMP AH, KeyBallPosLestX
    JNE GameState_BallMostX
    SendChar GameReceivedChar
    DrawBall ArenaBackColor
    MOV AL, GameReceivedChar
    AND AL, 00FH
    MOV BallPositionX, AL
    RET
    ;==================================
    
    ;Receive ball most significant x position
    GameState_BallMostX:
    CMP AH, KeyBallPosMostX
    JNE GameState_BallY
    SendChar GameReceivedChar
    MOV AL, GameReceivedChar
    AND AL, 00FH
    SHL AL, 1
    SHL AL, 1
    SHL AL, 1
    SHL AL, 1
    OR  BallPositionX, AL
    RET
    ;==================================
    
    ;Receive ball y position
    GameState_BallY:
    CMP AH, KeyBallPosY
    JNE GameState_Paddle1
    SendChar GameReceivedChar
    MOV AL, GameReceivedChar
    AND AL, 00FH
    MOV BallPositionY, AL
    DrawBall BallColor
    RET
    ;==================================
    
    ;Receive paddle 1 start y position
    GameState_Paddle1:
    CMP AH, KeyPaddleY1
    JNE GameState_Paddle2
    DrawPaddle Paddle1StartX, Paddle1StartY, ArenaBackColor
    MOV AL, GameReceivedChar
    AND AL, 00FH
    MOV Paddle1StartY, AL
    DrawPaddle Paddle1StartX, Paddle1StartY, PaddleColor
    RET
    ;==================================
    
    ;Receive paddle 2 start y position
    GameState_Paddle2:
    CMP AH, KeyPaddleY2
    JNE GameState_Score1
    DrawPaddle Paddle2StartX, Paddle2StartY, ArenaBackColor
    MOV AL, GameReceivedChar
    AND AL, 00FH
    MOV Paddle2StartY, AL
    DrawPaddle Paddle2StartX, Paddle2StartY, PaddleColor
    RET
    ;==================================
    
    ;Receive player 1 score
    GameState_Score1:
    CMP AH, KeyScore1
    JNE GameState_Score2
    MOV Score1, AL
    ADD Score1, '0'
    MOV ServeTurn, 2
    CALL ResetGame
    RET
    ;==================================
    
    ;Receive player 2 score
    GameState_Score2:
    CMP AH, KeyScore2
    JNE GameState_Return
    MOV Score2, AL
    ADD Score2, '0'
    MOV ServeTurn, 1
    CALL ResetGame
    RET
    ;==================================
    
    GameState_Return:
    RET
ReceiveGameState ENDP
;===============================================================

;Processes main primary inputs, to be called regardless what game state is
ProcessPrimaryMainInput PROC
    MOV AL, 2
    SUB AL, IsMainPlayer    ;AL=Player Index
    ProcessMainInput GameSentChar, AL
    RET
ProcessPrimaryMainInput ENDP
;===============================================================

;Processes main primary inputs, to be called regardless what game state is
ProcessSecondaryMainInput PROC
    MOV AL, 1
    ADD AL, IsMainPlayer    ;AL=Other Player Index
    ProcessMainInput GameReceivedChar, AL
    RET
ProcessSecondaryMainInput ENDP
;===============================================================

;Processes game primary user input
ProcessPrimaryGameInput PROC
    CMP IsMainPlayer, 1
    JE Process1
    RET
    Process1:
    ProcessGameInput GameSentChar, Paddle1StartX, Paddle1StartY, KeyPaddleY1
    RET
ProcessPrimaryGameInput ENDP
;===============================================================

;Processes game secondary user input
ProcessSecondaryGameInput PROC
    CMP IsMainPlayer, 1
    JE Process2
    RET
    Process2:
    ProcessGameInput GameReceivedChar, Paddle2StartX, Paddle2StartY, KeyPaddleY2
    RET
ProcessSecondaryGameInput ENDP
;===============================================================

;Processes chat primary user input
ProcessPrimaryChatInput PROC
    ProcessChatInput GameSentChar, User1CursorX, User1CursorY, ChatStartY
    RET
ProcessPrimaryChatInput ENDP
;===============================================================

;Process chat secondary user input
ProcessSecondaryChatInput PROC
    ProcessChatInput GameReceivedChar, User2CursorX, User2CursorY, ChatStartY+ChatAreaHeight
    RET
ProcessSecondaryChatInput ENDP
;===============================================================

;Moves the ball one step with its current velocity
MoveBall PROC
    ;If waiting serve then return
    CMP BallVelocityX, 0
    JNE MoveBall_Start
    RET
    MoveBall_Start:

    ;Clear ball
    DrawBall ArenaBackColor
    
    ;Move/Reflect the ball or determine that one player score a point
    CMP BallVelocityX, 0
    JG CheckOnPlayer2
    
    CheckOnPlayer1:
    CALL CheckPlayer1Net
    JMP MoveBall_Continue
    
    CheckOnPlayer2:
    CALL CheckPlayer2Net
    
    MoveBall_Continue:
    
    ;
    ;Send ball position to secondary computer
    ;
    ;Ball least significant x position
    MOV AL, BallPositionX
    AND AL, 00FH
    SendAppVariables KeyBallPosLestX, AL
    ReceiveAppVariables GameSentChar
    ;==================================
    ;Ball most significant x position
    MOV AL, BallPositionX
    SHR AL, 1
    SHR AL, 1
    SHR AL, 1
    SHR AL, 1
    SendAppVariables KeyBallPosMostX, AL
    ReceiveAppVariables GameSentChar
    ;==================================
    ;Ball y position
    SendAppVariables KeyBallPosY, BallPositionY
    ReceiveAppVariables GameSentChar
    ;==================================
    
    ;Draw the ball in its new position
    DrawBall BallColor

    RET
MoveBall ENDP
;===============================================================

;
CheckPlayer1Net PROC
    CheckForValidityAndMove Paddle1StartX, Paddle1StartY, 1
    RET
CheckPlayer1Net ENDP
;===============================================================

;
CheckPlayer2Net PROC
    CheckForValidityAndMove Paddle2StartX, Paddle2StartY, 2
    RET
CheckPlayer2Net ENDP
;===============================================================

;Initializes game variables
InitGame PROC
    ;Initialize game variables
    MOV Score1, '0'
    MOV Score2, '0'
    MOV IsGameEnded, 0
    MOV LoserIdx, 0
    MOV ServeTurn, 1
    
    ;Initialize locations
    MOV Paddle1StartY, ArenaHeight/2-PaddleHeight/2
    MOV Paddle2StartY, ArenaHeight/2-PaddleHeight/2
    MOV BallPositionX, Paddle1StartX+1
    MOV BallPositionY, ArenaHeight/2+ArenaStartY
    MOV BallVelocityX, 0
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, 0
    MOV CurrentVelocityY, 0
    
    ;Initialize inline chat variables
    MOV User1CursorX, ChatMsgMargin
    MOV User1CursorY, ChatStartY
    MOV User2CursorX, ChatMsgMargin
    MOV User2CursorY, ChatStartY+ChatAreaHeight
    
    ;Initialize game screen
    ClearScreen 0, 0, WindowWidth, WindowHeight
    CALL DrawGameScreen
    CALL DrawChatArea
    CALL DrawInfoBar
    
    ;Calculate game level
    CMP IsMainPlayer, 1
    JNE SecondaryPlayer
    
    MainPlayer:
    
    ;Send game level to secondary computer
    MOV AL, GameLevel
    SUB AL, '0'
    SendAppVariables KeyGameLevel, AL
    
    CMP GameLevel, '1'
    JNE GameLevel2
    
    ;Set game speed based on the chosen level
    GameLevel1:
    MOV OuterWaitLoopInit, OuterWaitLoopInit1
    MOV InnerWaitLoopInit, InnerWaitLoopInit1
    RET
    
    GameLevel2:
    MOV OuterWaitLoopInit, OuterWaitLoopInit2
    MOV InnerWaitLoopInit, InnerWaitLoopInit2
    RET
    ;==================================
    
    SecondaryPlayer:
    
    ;Clear info bar
    ClearScreen ChatMargin, InfoBarStartY+1, WindowWidth, InfoBarStartY+1, CurrentPage
    
    ;Print waiting game level message
    SetCursorPos ChatMargin, InfoBarStartY+1, CurrentPage
    PrintString WaitingGameLevelMsg
    
    ;Hide the cursor some where in the screen
    SetCursorPos WindowWidth, WindowHeight, 0
    
    ;Receive game level from main computer
    ReceiveGameLevel:
    
    ;Breaking condition to avoid infinite loop if connection lost
    GetKeyPressAndFlush
    CMP AL, ESC_AsciiCode
    JNE ReceiveGameLevel_Continue
    MOV IsGameEnded, 1
    MOV GameSentChar, AL
    SendChar GameSentChar
    RET
    
    ReceiveGameLevel_Continue:
    ReceiveChar
    JZ ReceiveGameLevel

    ;AH=key, AL=value
    MOV AH, AL
    AND AH, 0F0H
    AND AL, 00FH
    
    CMP AH, KeyGameLevel
    JNE ReceiveGameLevel
    
    MOV GameLevel, AL
    ADD GameLevel, '0'
    CALL DrawScore
    CALL DrawInfoBar
    
    RET
InitGame ENDP
;===============================================================

;Resets the game with its intial values
ResetGame PROC
    CMP Score1, MaxScoreValue
    JAE GameOver
    CMP Score2, MaxScoreValue
    JAE GameOver
    
    DrawBall ArenaBackColor
    
    MOV LoserIdx, 0
    MOV Paddle1StartY, ArenaHeight/2-PaddleHeight/2
    MOV Paddle2StartY, ArenaHeight/2-PaddleHeight/2
    MOV BallVelocityX, 0
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, 0
    MOV CurrentVelocityY, 0
    MOV BallPositionY, ArenaHeight/2+ArenaStartY
    
    CMP ServeTurn, 1
    JNE ServeTurn2
    
    ServeTurn1:
    MOV BallPositionX, Paddle1StartX+1
    JMP ResetGame_Continue
    
    ServeTurn2:
    MOV BallPositionX, Paddle2StartX-1
    
    ResetGame_Continue:
    CALL DrawGameScreen
    RET
    
    GameOver:
    CALL DrawScore
    MOV IsGameEnded, 1
    RET
ResetGame ENDP
;===============================================================

;Updates the score of game if one player scores
UpdateScore PROC
    ;The loser is the one who has the turn to serve
    MOV AL, LoserIdx
    MOV ServeTurn, AL   ;ServeTurn=LoserIdx

    CMP LoserIdx, 2
    JNE GameReset_Player2
    
    ;Player 1 scores a point
    GameReset_Player1:
    INC Score1
    MOV AL, Score1
    SUB AL, '0'
    SendAppVariables KeyScore1, AL
    RET
    
    ;Player 2 scores a point
    GameReset_Player2:
    INC Score2
    MOV AL, Score2
    SUB AL, '0'
    SendAppVariables KeyScore2, AL
    RET
UpdateScore ENDP
;===============================================================

;Draws the entire game frame
DrawGameScreen PROC
    ;Clear screen
    ClearScreen ArenaStartX, ArenaStartY, ArenaWidth, ArenaScoreEndY+ArenaBorderWidth-1

    ;Draw arena with paddles and score
    CALL DrawArena
    CALL DrawPaddles
    CALL DrawScore
    DrawBall BallColor
    
    RET
DrawGameScreen ENDP
;===============================================================

;Draws pong game borders
DrawArena PROC
    DrawLine ArenaStartX, ArenaStartY   , ArenaBorderWidth, ArenaWidth, ArenaBorderChar, ArenaBorderColor, CurrentPage
    DrawLine ArenaStartX, ArenaEndY     , ArenaBorderWidth, ArenaWidth, ArenaBorderChar, ArenaBorderColor, CurrentPage
    DrawLine ArenaStartX, ArenaScoreEndY, ArenaBorderWidth, ArenaWidth, ArenaBorderChar, ArenaBorderColor, CurrentPage
    RET
DrawArena ENDP
;===============================================================

;Draws game paddles
DrawPaddles PROC
    DrawPaddle Paddle1StartX, Paddle1StartY, PaddleColor
    DrawPaddle Paddle2StartX, Paddle2StartY, PaddleColor
    RET
DrawPaddles ENDP
;===============================================================

;Draws game score and level
DrawScore PROC
    ;Game level
    SetCursorPos GameLevelStartX, ScoreStartY, CurrentPage
    PrintString GameLevelLabel
    PrintChar GameLevel
    ;==================================
    
    ;Player names
    ;Print colons and scores
    SetCursorPos Score1StartX+MaxUserNameSize, ScoreStartY, CurrentPage
    PrintChar ':'
    SetCursorPos Score1StartX+MaxUserNameSize+2, ScoreStartY, CurrentPage
    PrintChar Score1
    SetCursorPos Score2StartX+MaxUserNameSize, ScoreStartY, CurrentPage
    PrintChar ':'
    SetCursorPos Score2StartX+MaxUserNameSize+2, ScoreStartY, CurrentPage
    PrintChar Score2
    
    CMP IsMainPlayer, 1
    JNE GameScore_SecondaryPlayer
    
    ;Main player
    GameScore_MainPlayer:
    SetCursorPos Score1StartX, ScoreStartY, CurrentPage
    PrintString UserName1
    ;Other player
    SetCursorPos Score2StartX, ScoreStartY, CurrentPage
    PrintString UserName2
    RET
    
    ;Main player
    GameScore_SecondaryPlayer:
    SetCursorPos Score1StartX, ScoreStartY, CurrentPage
    PrintString UserName2
    ;Other player
    SetCursorPos Score2StartX, ScoreStartY, CurrentPage
    PrintString UserName1
    RET
DrawScore ENDP
;===============================================================

;Draws chat area and players name
DrawChatArea PROC
    ;Primary player
    GameChat_MainPlayer:
    SetCursorPos ChatMargin, ChatStartY, CurrentPage
    PrintString UserName1
    SetCursorPos ChatMargin+MaxUserNameSize, ChatStartY, CurrentPage
    PrintChar ':'
    
    ;Secondary player
    SetCursorPos ChatMargin, ChatStartY+ChatAreaHeight, CurrentPage
    PrintString UserName2
    SetCursorPos ChatMargin+MaxUserNameSize, ChatStartY+ChatAreaHeight, CurrentPage
    PrintChar ':'
    RET
DrawChatArea ENDP
;===============================================================

;Draws the information bar to show messages to user
DrawInfoBar PROC
    ;Draw begin separator
    DrawLine ChatStartX, InfoBarStartY, 1, ChatAreaWidth, ChatLineChar, ChatLineColor, CurrentPage
    ;Clear info bar
    ClearScreen ChatMargin, InfoBarStartY+1, WindowWidth, InfoBarStartY+1, CurrentPage
    ;Print info message
    SetCursorPos ChatMargin, InfoBarStartY+1, CurrentPage
    PrintString EndGameMsg
    ;Draw end separator
    DrawLine ChatStartX, InfoBarStartY+2, 1, ChatAreaWidth, ChatLineChar, ChatLineColor, CurrentPage
    RET
DrawInfoBar ENDP
;===============================================================

;Draws game over for 5 seconds then returns
DrawEndScreen PROC
    ;Clear info bar
    ClearScreen ChatMargin, InfoBarStartY+1, WindowWidth, InfoBarStartY+1, CurrentPage
    
    ;Print quitting message
    SetCursorPos ChatMargin, InfoBarStartY+1, CurrentPage
    PrintString GameOverMsg
    
    ;Hide the cursor some where in the screen
    SetCursorPos WindowWidth, WindowHeight, 0
    
    MOV AX, 0FFFH
    MOV BX, 04FFH
    
    GameOver_Loop:
    DEC BX
    JNZ GameOver_Loop
    MOV BX, 04FFH
    DEC AX
    JNZ GameOver_Loop
    
    EmptyKeyQueue
    
    RET
DrawEndScreen ENDP
;===============================================================

;Gets random ball velocity vector
GetRandomBallDirection PROC
    ;Get system time. Return: CH=hour CL=minute DH=second DL=1/100seconds
    MOV AH, 2CH
    INT 21H

    ;AH = time.seconds mod 5
    MOV AH, 0
    MOV AL, DH
    MOV BL, 5
    DIV BL

    Rem0:
    CMP AH, 0
    JNE Rem1
    MOV BallVelocityX, 1
    MOV BallVelocityYEven, 1
    MOV BallVelocityYOdd, 1
    MOV CurrentVelocityY, 1
    RET

    Rem1:
    CMP AH, 1
    JNE Rem2
    MOV BallVelocityX, 1
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, 0
    MOV CurrentVelocityY, 0
    RET
    
    Rem2:
    CMP AH, 2
    JNE Rem3
    MOV BallVelocityX, 1
    MOV BallVelocityYEven, -1
    MOV BallVelocityYOdd, -1
    MOV CurrentVelocityY, -1
    RET
    
    Rem3:
    CMP AH, 3
    JNE Rem4
    MOV BallVelocityX, 1
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, 1
    MOV CurrentVelocityY, 0
    RET
    
    Rem4:
    ;CMP AH, 4
    MOV BallVelocityX, 1
    MOV BallVelocityYEven, 0
    MOV BallVelocityYOdd, -1
    MOV CurrentVelocityY, 0
    RET
GetRandomBallDirection ENDP
;===============================================================

END