module DungeonOfDoom

  class GameModule

    #Constants
    #General Messages
    MSG_BLOW    = 'A GOOD BLOW'
    MSG_HIT     = 'WELL HIT SIRE'
    MSG_AIM     = 'THY AIM IS TRUE'
    MSG_MISS    = 'MISSED'
    MSG_DAMGAGE = 'HIT THEE!!'
    MSG_KILL    = 'THE MONSTER IS SLAIN'
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
    POS_TURN  = [POS_EAST,POS_SOUTH,POS_WEST,POS_NORTH]
    POS_STR   = 'NESWD'
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
      @torch_power = 0
      @potions = 0
      @attack = 0
      @idol_found = false
      @spells = {}
      @dungeon_file = nil
      @current_level = 1 #always start with at level 1
      @start_x = 0
      @start_y = 0
      @cur_x = 0
      @cur_y = 0
      @hero_direction = POS_EAST #initial direction

      #set up 15x15 room with the space character as the default floow
      @room = Array.new(15) { Array.new(15, DungeonOfDoom::CHAR_FLOOR)}
    end

    # Main entry point.  Load Hero and Dungeon Map file and start the game
    def run
      #Load the Hero File
      load_hero_file
      #Load dungeon at top level
      load_dungeon_file(@current_level)
      #display the hero's starting spot
      clear_message_box
      #get input either an action or a movement.
      key = nil
      while true
        update_screen
        key = @ui.instr
        case key
          when 'B','b' #turn left
            @hero_direction = POS_TURN.rotate!(-1)[0]
          when 'N','n' #turn right
            @hero_direction = POS_TURN.rotate!(1)[0]
          when 'M','m' #move ahead
            move_hero
          when 'A','a' #attack
          when 'C','c' #cast
          when 'G','g' #get
            get_object
          when 'P','p' #potion
            drink_potion
          when 'R','r' #reveal
            light_room
          when 'S','s' #save?
            #not implemented yet
          when 'Q','q' #quit
            if ask_question("DO YOU REALLY WANT","TO QUIT? (Y/N)") == 'Y'
              break
            else
              clear_message_box
            end
        end
      end
    end

    private

    #Move the Hero.  First get the next square that the hero will move into.  If its somthing that
    #can't be stood on, then block the move.  IE a wall or monster.  But a down passage, trap and
    #safe spot can be walked over.  Traps will hold a player in that spot for some random move.
    #Walking into walls does damage, but walking will increase health over time.  If Monster is
    #within range then call the monster sub routine.
    def move_hero
      #get next square
      next_x = @cur_x + DIRECTION[@hero_direction][0]
      next_y = @cur_y + DIRECTION[@hero_direction][1]
      next_x = 0 if next_x < 0
      next_x = 14 if next_x > 14
      next_y = 0 if next_y < 0
      next_y = 14 if next_y > 14
      #look at new square in room
      next_square = @room[next_x][next_y]
      draw_map(next_x,next_y)
      #don't move onto it if next square is an object that can't be walked over
      if next_square == CHAR_FLOOR || next_square == CHAR_IN || next_square == CHAR_OUT ||
         next_square == CHAR_TRAP || next_square == CHAR_SAFE
        #walked into trap, keep on trap unless strong and lucky
        if @room[@cur_x][@cur_y] == CHAR_TRAP &&
           @stats[:strength] <= (@orig_stats[:strength] * 0.8) &&
           @stats[:luck] <= Random.rand(15)
          next_x = @cur_x
          next_y = @cur_y
        end
        #increase health on any move
        @stats[:strength] += (@stats[:vitality] / 200.0) if @stats[:strength] < @orig_stats[:strength]
        #move the character
        if next_x != @cur_x || next_y != @cur_y
          draw_map(@cur_x, @cur_y)
          @cur_x = next_x
          @cur_y = next_y
          draw_map(@cur_x, @cur_y)
        end
      end
      #cause damage if walked into wall
      if next_square == CHAR_WALL
        @stats[:strength] -= 0.3
      end

      #monster detected

      #dead
    end

    #pick up an object, either a potion, treasure or idol.  Potion will add to potion count
    #treasure will add to final score and if idol then game over. You win!
    def get_object
      next_x = @cur_x + DIRECTION[@hero_direction][0]
      next_y = @cur_y + DIRECTION[@hero_direction][1]
      return if next_x < 0 || next_x > 14 || next_y < 0 || next_y > 14
      #look at new square in room
      next_square = @room[next_x][next_y]
      if next_square == CHAR_POTION || next_square == CHAR_CHEST || next_square == CHAR_IDOL
        @room[next_x][next_y] = CHAR_FLOOR
        draw_map(next_x,next_y)
        @potions += 1 if next_square == CHAR_POTION
        @treasure += 1 if next_square == CHAR_CHEST
        @idol_found = true if next_square == CHAR_IDOL
      end
    end

    #drink a potion to revive strength
    def drink_potion
      if @potions > 0
        @stats[:strength] = @orig_stats[:strength]
        @potions -= 1
      end
    end

    #Update character position and stats
    def update_screen
      #ensure immediate squars around hero can be seen
      light_room(false) #but don't use torch
      #draw hero
      @ui.place_text(DungeonOfDoom::CHAR_PLAYER[@hero_direction], @cur_x+2, @cur_y+6, DungeonOfDoom::C_WHITE_ON_RED)
      #draw stats
      @ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
      @ui.place_text(@stats[:strength].round.to_s.ljust(4),17,7)
      @ui.place_text(@stats[:vitality].round.to_s.ljust(4),17,10)
      @ui.place_text(@stats[:aura].round.to_s.ljust(4),17,13)
      @ui.place_text(POS_STR[@hero_direction],17,16)
      @ui.place_text(@stats[:experience].to_s.ljust(4),17,19)
      @ui.place_text(@attack.to_s.ljust(3),2,22)
      @ui.place_text(@spells.values.inject(0){|power,total| total+=power}.to_s.ljust(3),6,22)
      @ui.place_text(@torch_power.to_s.ljust(3),13,22)
      @ui.place_text(@potions.to_s.ljust(3),17,22)
    end

    #Light the room up around the hero.  Set use torch if using torch otherwise just a normal view
    def light_room(use_torch=true)
      if use_torch && @torch_power == 0
        clear_message_box
        @ui.place_text(MSG_DARK.ljust(20),1,2)
      else
        area = use_torch ? 3 : 1
        (@cur_x-area..@cur_x+area).each do |row|
          (@cur_y-area..@cur_y+area).each do |col|
            if (row >= 0 && row <= 14) && (col >= 0 and col <= 14) && !(row == @cur_x && col == @cur_y)
              draw_map(row,col)
            end
          end
        end
        @torch_power -= 1 if use_torch
      end
    end

    #Draw map at position x,y
    def draw_map(x,y)
      @ui.place_text(@room[x][y], x+2, y+6, DungeonOfDoom::C_YELLOW_ON_RED)
    end

    #Clears the message box
    def clear_message_box
      (2..5).each { |y| @ui.place_text(' '*20,1,y, DungeonOfDoom::C_BLACK_ON_YELLOW) }
    end

    #Ask Question, Up to three lines, message is mandatory, returns results of answer
    def ask_question(message, message1=nil, message2=nil)
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text(message.ljust(20),1,2)
      @ui.place_text(message1.ljust(20),1,3) if message1
      @ui.place_text(message2.ljust(20),1,4) if message2
      cursor_spot = if message1.nil? && message2.nil?
        3
      elsif message2.nil?
        4
      else
        5
      end
      @ui.place_text('>'.ljust(20),1,cursor_spot)
      @ui.get_string(2,cursor_spot).upcase
    end

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
            #set torch power
            torch = @objects.find { |object| object[:name]=='TORCH' }
            @torch_power = torch[:power] if torch
            #find initial potion count
            potion = @objects.find { |object| object[:name]=='POTION' }
            @potions += potion[:count] if potion
            #find initial attack power
            ['2 HAND SWORD','BROADSWORD','SHORTSWORD','AXE','MACE','FLAIL','DAGGER','GAUNTLET'].each do |item|
              object = @objects.find { |object| object[:name]==item }
              @attack += object[:power] if object
            end
            @attack += @stats[:strength]
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
          @cur_x = @start_x
          @cur_y = @start_y
        else
          @ui.place_text("!LEVEL #{level} NOT FOUND".ljust(20),1,4)
          @ui.place_text('!BAD DUNGEON FILE'.ljust(20),1,5)
        end
      end
    end

  end
end