module DungeonOfDoom

  class GameModule

    #Constants
    #General Messages
    MSG_BLOW    = 'A GOOD BLOW'
    MSG_HIT     = 'WELL HIT SIRE'
    MSG_AIM     = 'THY AIM IS TRUE'
    MSG_MISS    = 'MISSED'
    MSG_DAMGAGE = 'HIT THEE!!'
    MSG_KIKK    = 'THE MONSTER IS SLAIN'
    MSG_DARK    = 'NO LIGHT'
    MSG_BROKEN  = 'BROKEN THY '
    MSG_SPELL   = 'SPELL EXHAUSED'
    MSG_KEY     = 'PRESS ANY KEY'
    MSG_EXP     = 'YOU NEED EXPERIENCE'
    MSG_EXIT    = 'EXIT FROM THIS LEVEL '
    MSG_ATTACK  = [MSG_BLOW,MSG_HIT,MSG_AIM]

    #Facing direction for lookup into movement array
    POS_NORTH = 0
    POS_EAST  = 1
    POS_SOUTH = 2
    POS_WEST  = 3
    #Movement X,Y move based on characters facing direction IE: South=2 so move X=>0 and Y=>1 (DOWN)
    DIRECTION =[[0,-1],[1,0],[0,1],[-1,0]]

    #Override Level decending based on experience
    LEVEL_EXPERIENCE_CHECK = true

    def initialize
      #set up screen for the game
      @ui = DungeonOfDoom::ScreenHandler.new(22,24)
      #draw the game title
      @ui.place_text('ROLE PLAYING GAME'.center(20), 1, 1, DungeonOfDoom::C_BLACK_ON_WHITE)
      #draw message area
      @ui.draw_box(20,4,1,2,DungeonOfDoom::C_BLACK_ON_YELLOW)
      #draw the room box
      @ui.draw_box(20,17,1,6,DungeonOfDoom::C_WHITE_ON_RED)
      @ui.draw_box(15,15,2,6,DungeonOfDoom::C_WHITE_ON_BLACK)
      #draw stats titles
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text('STR',17,6)
      @ui.place_text('VIT',17,9)
      @ui.place_text('AUR',17,12)
      @ui.place_text('FACE',17,15)
      @ui.place_text('EXP',17,18)
      @ui.place_text('ATT',2,21)
      @ui.place_text('SPELLS',6,21)
      @ui.place_text('CAN',13,21)
      @ui.place_text('POT',17,21)

      #game variables
      @stats = {}
      @orig_stats = {}
      @objects = nil
      @treasure = 0
      @gold_count = 0
      @spells = {}
      @dungeon_file = nil
      @current_level = 1 #always start with at level 1
      @start_x = 0
      @start_y = 0
      #set up 15x15 room with the space character as the default floow
      @room = Array.new(15) { Array.new(15, DungeonOfDoom::CHAR_FLOOR)}
    end

    # Main entry point.  Load Hero and Dungeon Map file and start the game
    def run
      #Load the Hero File
      load_hero_file
      #Load dungeon at top level
      load_dungeon_file(@current_level)

@ui.input
    end

    private

    #Ask the user for the hero file.  Hero file must be in yaml format which was generated
    #from the character_creator.rb file.  Once loaded, store vitals for gameplay and display
    #the heros name.  Yaml file should have 4 keys, :stats, :objects, :gold and :name
    def load_hero_file
      clear_message_box
      #ask for file
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text('USE CHARACTER FILE?'.ljust(20),1,2)
      @ui.place_text('>'.ljust(20),1,3)
      file_name=nil
      #loop until file is good
      while file_name.nil?
        @ui.place_text(' '*19,2,3)
        file_name = @ui.get_string(2,3)
        #check and try to open file
        if file_name.split('.').last != 'yaml'  #needs yaml extention
          @ui.place_text('!REQUIRES YAML EXT'.ljust(20),1,4)
          file_name=nil
        elsif !File.exists?(file_name)  #file must exist
          @ui.place_text('!FILE NOT FOUND'.ljust(20),1,4)
          file_name=nil
        else
          hero_data = YAML.load(File.open(file_name))
          if !hero_data.is_a? Hash   #file must be in a valid yaml format
            @ui.place_text('!FILE BAD FORMAT'.ljust(20),1,4)
            file_name=nil
          else  #all okay!
            #load stats
            hero_data[:stats].each do |stat|
              @stats[stat[0].downcase.to_sym] = stat[1]
            end
            @orig_stats.merge!(@stats) #make a copy
            #load objects
            @objects = hero_data[:objects]
            #load remaining gold (used for final score)
            @gold_count += hero_data[:gold]
            #display heros name
            @ui.place_text(hero_data[:name].center(20), 1, 1, DungeonOfDoom::C_BLACK_ON_WHITE)
            #set magic spell count based on 2 x power of NECRONOMICON and SCROLLS
            book = @objects.find { |object| object[:name]=='NECRONOMICON' }
            if book
              power = book[:power]
              [:super_zap, :santuary, :teleport].each do |spell|
                @spells[spell] = 2*power
              end
            end
            scroll = @objects.find { |object| object[:name]=='SCROLLS' }
            if scroll
              power = scroll[:power]
              [:powersurge, :metamorphosis, :healing].each do |spell|
                @spells[spell] = 2*power
              end
            end
          end
        end
      end
    end

    #Ask the user for the map or dungeon file.  Dungeon file must be generated from the
    #dungeon_generator.rb file.  Each line of the file is a level.  The first (15x15)
    #charaters is the map, the next 4 digits is the start position (x,y) and the last 2 digits
    #is the level number.  Only one level is needed at one time, the level loaded is based on
    #the level parameter.  The level can't be reached unless the hero has enough experience.  This
    #can be overriden by a constant.
    def load_dungeon_file(level)
      clear_message_box
      #ask for file if necessary
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      unless @dungeon_file
        @ui.place_text('USE DUNGEON FILE?'.ljust(20),1,2)
        @ui.place_text('>'.ljust(20),1,3)
        #loop until file is good
        while @dungeon_file.nil?
          @ui.place_text(' '*19,2,3)
          @dungeon_file = @ui.get_string(2,3)
          #check to see if file exists
          if !File.exists?(@dungeon_file)  #file must exist
            @ui.place_text('!FILE NOT FOUND'.ljust(20),1,4)
            @dungeon_file=nil
          end
        end
      end
      #check if here has enough experience to enter level
      if LEVEL_EXPERIENCE_CHECK && level > @stats[:experience]
        @ui.place_text(MSG_EXP.ljust(20),1,4)
      else
        #all okay, load level and start location
        levels = IO.readlines(@dungeon_file)
        new_level = levels.find do |data|
          #level data should be at position (15x15)+4=229
          data[229..230].to_i == level
        end
        if new_level
          #okay level found
          data = new_level.chars.to_a #make and array of characters
          (0..14).each do |row|
            (0..14).each do |col|
              @room[row][col] = data[(15*row)+col]
            end
          end
          @start_x = (data[225]+data[226]).to_i
          @start_y = (data[227]+data[228]).to_i
        else
          @ui.place_text("!LEVEL #{level} NOT FOUND".ljust(20),1,4)
          @ui.place_text('!BAD DUNGEON FILE'.ljust(20),1,5)
        end
      end
    end

# 1770 COLOUR 128:COLOUR 3:PRINT TAB(0,3);"PREPARE DUNGEON FILE"
# 1780 LET M$=T$(10):GOSUB 370
# 1790 S=OPENIN "LEVEL"
# 1795 FOR I=1 TO LV
# 1800 INPUT#S,S$
# 1805 NEXT I
# 1810 CLOSE#S
# 1820 LET I=1
# 1830 FOR Y=1 TO 15
# 1840 FOR X=1 TO 15
# 1850 LET R(X,Y)=ASC(MID$(S$,I,1))
# 1860 LET I=I+1
# 1870 NEXT X
# 1880 NEXT Y
# 1890 LET IX=ASC(MID$(S$,I,1))-OS
# 1900 LET IY=ASC(MID$(S$,I+1,1))-OS
# 1910 LET LE=ASC(MID$(S$,I+2,1))-OS
# 1920 IF LE>F(5) THEN GOSUB 1960:GOTO 1760
# 1930 GOSUB 2790
# 1940 LET NX=IX:LET NY=IY:LET OX=NX:LET OY=NY:LET DX=255
# 1950 RETURN
# 1960 PRINT:PRINT "LEVEL TOO DEEP"
# 1970 PRINT "REWIND FILE"
# 1980 PRINT "TO POSITION"
# 1990 PRINT "FOR LEVEL ";F(5)
# 2000 RETURN

    def clear_message_box
      (2..5).each { |y| @ui.place_text(' '*20,1,y, DungeonOfDoom::C_BLACK_ON_YELLOW) }
    end

  end
end