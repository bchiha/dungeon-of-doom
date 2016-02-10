module DungeonOfDoom
  VERSION = '0.0.1'

  # Define character shapes
  CHAR_FLOOR  = ' '      #blank
  CHAR_WALL   = "\u2588" #█
  CHAR_POTION = "\u265C" #♜
  CHAR_CHEST  = "\u2388" #⎈
  CHAR_IDOL   = "\u2655" #♕
  CHAR_IN     = "\u2617" #☗
  CHAR_OUT    = "\u2616" #☖
  CHAR_TRAP   = "\u2622" #☢
  CHAR_SAFE   = "\u2716" #✖
  CHAR_MONST  = "\u260a\u0298\u237e" #☊ʘ⍾
  CHAR_PLAYER = "\u25b2\u25b6\u25bc\u25c0\u2620" #▲▶▼◀☠
  # Grouping of static map characters, the order here is important
  MAP_TILES   = [CHAR_FLOOR,CHAR_WALL,CHAR_POTION,CHAR_CHEST,CHAR_IDOL,CHAR_IN,
                 CHAR_OUT,CHAR_TRAP,CHAR_SAFE,CHAR_MONST]

  # Define internal colour constants
  C_WHITE_ON_RED    = 1
  C_RED_ON_YELLOW   = 2
  C_BLACK_ON_YELLOW = 3
  C_YELLOW_ON_WHITE = 4
  C_BLACK_ON_WHITE  = 5
  C_WHITE_ON_BLACK  = 6
  C_YELLOW_ON_RED   = 7
  C_YELLOW_ON_BLACK = 8
  C_RED_ON_WHITE    = 9
end
