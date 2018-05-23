# Pong
A simple 2-player pong game with chat capability.

The players are connected through serial communication between 2 computers.

The game is written in x86 assembly language for Microprocessors course.

### How to use?
* Clone this repository.
* Make sure to install DOS box.
* Assemble Main.asm, Game.asm, and Chat.asm files from the DOS box using
<br>`masm code\Main.asm;`
<br>`masm code\Game.asm;`
<br>`masm code\Chat.asm;`

* Link the `.obj` object files from the DOS box using
<br>`link Main+Game+Chat;`

* Connect to anothor computer using serial cable or using virtual serial ports.
* Run the ouput `.exe` file and enjoy.


### Screenshots

![alt text](https://raw.githubusercontent.com/OmarBazaraa/Pong/master/screenshots/1.png)

![alt text](https://raw.githubusercontent.com/OmarBazaraa/Pong/master/screenshots/2.png)

![alt text](https://raw.githubusercontent.com/OmarBazaraa/Pong/master/screenshots/3.png)
