dungeon-of-doom
===============

Dungeon of Doom is an RPG game the was firstly published by Usborne in 1984 with the book 'Write Your Own Fantasy Games (Usborne Computers &amp; Electronics)'.  This is a ruby rewrite

## REQUIREMENTS:

* ruby 1.9

* uses _curses_ library which comes with ruby 1.9 but in order to get UTF-8 characters to work ruby needs to be compiled with libncursesw5-dev.  Install this libaray first before compiling ruby.  Using *rvm reinstall*  makes this task really easy.

## SETUP and FILE DESCRIPTIONS

* **bbc** - original bbc basic source code.  Need a BBC emulator to run

* **bin** - executables and sample dungeon map and charaters.  **char_gen** is the character generator, **dun_gen** is the dungeon generator and **dod** is the main game.  Need to make these files executable by doing a `$chmod 755` on `bin/char_gen`, `bin/dun_gen` and `bin/dod`.  `dungeon` file is a sample dungeon map and `mage.yaml` and `barb.yaml` are sample character files 

* **game_instructions.pdf** - Book of Lore.  Game playing instrucitons for the main game.  The dungeon and character generator programs have slightly different commands.  Press '?' while in these programs for commands.

* **lib** - source code

## PLAY THE GAME

If you have ruby 1.9 and its compiled with libncurses5-dev then

```
$cd bin
$./char_gen
$./dun_gen
$./dod
```

## NOTES

If you are having problems with the character sets, just change them in `lib\dungeon_of_doom\constants.rb`.  The code was written for high school students to learn ruby.  Hence it was written to be easily read and well documented.  So areas of the code would be deemed inefficient for this reason.


