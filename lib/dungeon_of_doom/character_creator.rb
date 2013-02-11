module DungeonOfDoom

  class CharacterCreator

    # Constants
    BASE_CHARACTER_STAT = 5 #base character stat value
    STAT_MARGIN         = 2 #stat variance
    BASE_POINTS         = 3 #base points to allocate
    POINTS_MARGIN       = 5
    BASE_GOLD           = 120
    GOLD_MARGIN         = 60
    CURSOR_SYMBOL       = '>'
    # Pages to go from, order is important
    PAGES = ['CHARACTER CREATION','WEAPONS','ARMOUR','EMPORIUM']
    # Characters
    CHAR_WAND = 'WANDERER'
    CHAR_CLER = 'CLERIC'
    CHAR_MAGE = 'MAGE'
    CHAR_WARR = 'WARRIOR'
    CHAR_BARB = 'BARBARIAN'
    CHARACTER = [CHAR_WAND,CHAR_CLER,CHAR_MAGE,CHAR_WARR,CHAR_BARB]
    # FLAGS FOR CHAR WITH OBJECTS
    CHAR_F_WAND = 1
    CHAR_F_CLER = 2
    CHAR_F_MAGE = 4
    CHAR_F_WARR = 8
    CHAR_F_BARB = 16

    def initialize
      #set up screen for the generator
      @ui = DungeonOfDoom::ScreenHandler.new(22,24)
      #draw the message/title box
      @ui.draw_box(20,4,1,2,
                   DungeonOfDoom::C_BLACK_ON_YELLOW,
                   DungeonOfDoom::C_YELLOW_ON_WHITE)
      #draw the room box
      @ui.draw_box(20,17,1,6,
                   DungeonOfDoom::C_BLACK_ON_WHITE,
                   DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text(" "*20,1,1,DungeonOfDoom::C_YELLOW_ON_BLACK) #20 spaces

      #initialise character stats.  A hash of stat items
      @stats = set_up_stats
      @stat_points = BASE_POINTS+Random.rand(POINTS_MARGIN)+1

      #initialise objects
      @objects = set_up_objects
      @gold = BASE_GOLD+Random.rand(GOLD_MARGIN)+1

      #initial cursor item position (1-8)
      @cursor_at = 1
    end

    # Main entry point.  Take the user through the pages and saves the character
    def run
      #interate through 4 pages 0 to 3 (0 = Stats, 1-3 = Objects)
      (0..3).each do |page_no|
        #collect data for page and display the titles
        page_display = nil
        @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
        case page_no
        when 0
          page_display = @stats
          @ui.place_text('ALLOCATE_POINTS'.ljust(16),3,3)
          @ui.place_text('POINTS'.ljust(14),3,4)
          @ui.place_text(@stat_points.to_s.rjust(2),17,4)
        else
          page_display = @objects["page_#{page_no}".to_sym].map {|f| [f[:name],f[:cost]]}
          @ui.place_text('CHOOSE WELL SIRE'.ljust(16),3,3)
          @ui.place_text('GOLD COINS'.ljust(13),3,4)
          @ui.place_text(@gold.to_s.rjust(3),16,4)
        end
        @ui.place_text(PAGES[page_no].center(18), 2, 1, DungeonOfDoom::C_YELLOW_ON_BLACK)

        #display data on screen
        display_page(page_display)

        #reset cursor to position 1
        display_cursor(DungeonOfDoom::C_BLACK_ON_WHITE)
        @cursor_at=1
        display_cursor

        #manage page until space is pressed, then go to the next page
        key = nil
        while key != ' ' #space character
          key = @ui.instr
          case key
          when '?'
            display_help
          when 'l','L'
            update_stat(:up) if page_no==0
          when 'h','H'
            update_stat(:down) if page_no==0
          when 'k','K'
            move_cursor(:up)
          when 'j','J'
            move_cursor(:down)
          when 'b','B'
            buy_object if page_no > 0
          when 'o','O'
            bid_for_object if page_no > 0
          else
            #ignore key pressed
          end
        end
      end
    end

    private

    # Update player stats either up or down.  Can only update if points are remaining
    # If decreasing stats points can be reallocated.  Experience can't be updated.
    # Depending on how the points are spread, determines what type of CHARACTER the player
    # will be.  This is important as depending on character type, certian objects can't be
    # purchased at the shop.  Character allocation is as follows:
    #
    # IF Intelligence > 6 AND Morality > 7 then player will be a CLERIC
    # IF Intelligence > 8 AND Aura > 7 then player will be a MAGE
    # IF Strength > 7 AND Morality > 5 AND Strength+Vitality > 10 then player will be a WARRIOR
    # IF Strength > 8 AND Morality < 6 AND Vitality+Agility > 12 then player will be a BARBARIAN
    # ELSE the player will be a WANDERER
    def update_stat(direction)
      #check if okay to move first
      if @cursor_at != 8 && ((direction == :up && @stat_points > 0) || (direction == :down && @stats[@cursor_at-1][1]>0))
        case direction
        when :up
          @stat_points -= 1
          @stats[@cursor_at-1][1] += 1
        when :down
          @stat_points += 1
          @stats[@cursor_at-1][1] -= 1
        else
          #unknown direction
        end
        #display character type
        character = if @stats[3][1] > 6 && @stats[6][1] > 7
          CHAR_CLER
        elsif @stats[3][1] > 8 && @stats[5][1] > 7
          CHAR_MAGE
        elsif @stats[0][1] > 7 && @stats[6][1] > 5 && @stats[0][1]+@stats[1][1] > 10
          CHAR_WARR
        elsif @stats[0][1] > 8 && @stats[6][1] < 6 && @stats[1][1]+@stats[2][1] > 12
          CHAR_BARB
        else
          CHAR_WAND
        end
        @ui.place_text("CHAR: #{character}".ljust(16),3,3,DungeonOfDoom::C_BLACK_ON_YELLOW)
        #redraw screen
        @ui.place_text(@stat_points.to_s.rjust(2),17,4,DungeonOfDoom::C_BLACK_ON_YELLOW)
        display_page(@stats)
      end
    end

    # Display the text and value of each item on the screen, also, display the initial heading information
    def display_page(page_data)
      x, y = 3, 7 #starting x, y
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_WHITE)
      page_data.each do |data|
        @ui.place_text(data[0].ljust(13),x,y)
        @ui.place_text(data[1].to_s.rjust(2),x+14,y)
        y += 2
      end
    end

    # Cursor moving is in two steps, unset cursor at current position and
    # set the cursor at the new position.  Move the cursor either up or down,
    # and if cursor hits a boundry then don't change value.
    def move_cursor(direction)
      #reset the current square to orginal colour
      display_cursor(DungeonOfDoom::C_BLACK_ON_WHITE)

      #now move the cursor
      case direction
      when :up
        @cursor_at -=1 if @cursor_at != 1
      when :down
        @cursor_at +=1 if @cursor_at != 8
      else
        #unknown direction
      end

      #display the cursor at the new location
      display_cursor
    end

    # Display the cursor at its current position.  If force colour then erase the cursor character
    def display_cursor(force_colour=nil)
      @ui.place_text(force_colour ? ' ' : CURSOR_SYMBOL, 2, (@cursor_at-1)*2+7, force_colour || DungeonOfDoom::C_RED_ON_WHITE)
    end

    # Display the help messages
    def display_help
      #set up the help message
      help_message = ["PRESS ANY KEY","USE J K TO MOVE","SPACE - NEXT PAGE","H L ADD/REM POINTS",
                      "B TO PURCHASE","O TO MAKE AN OFFER","? FOR HELP"]
      help_message.each do |msg|
        @ui.place_text(msg.ljust(18),2,5,DungeonOfDoom::C_RED_ON_WHITE)
        @ui.input
      end
      @ui.place_text(" "*18,2,5,DungeonOfDoom::C_RED_ON_WHITE) #18 spaces
    end

    # Initialise the character statistics array.  These stats all play a part in
    # how the character plays the game.  Stats are randomly allocated to be between
    # BASE_CHARACTER_STAT +- STAT_MARGIN.  Experience is set to 1
    def set_up_stats
      stats_array = []
      random = Random.new
      ['STRENGTH', 'VITALITY', 'AGILITY', 'INTELLIGENCE', 'LUCK', 'AURA', 'MORALITY'].each do |stat|
        stats_array << [stat,random.rand(BASE_CHARACTER_STAT-STAT_MARGIN..BASE_CHARACTER_STAT+STAT_MARGIN)]
      end
      stats_array << ['EXPERIENCE',1]
      stats_array
    end

    # Initialise the objects array.  There are 24 objects in total.  These objects
    # are grouped into three pages.  Pages are ARMOURY,ACCOUTREMENTS,EMPORIUM, each
    # item has a cost, strength factor and character flags (ie can be used by a type
    # of character)
    def set_up_objects
      ob = {}
      #weapons
      ob[:page_1] = [{:name => '2 HAND SWORD', :cost => 20, :power => 5, :flags => CHAR_F_BARB},
                     {:name => 'BROADSWORD', :cost => 16, :power => 4, :flags => CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'SHORTSWORD', :cost => 12, :power => 3, :flags => CHAR_F_WAND | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'AXE', :cost => 15, :power => 3, :flags => CHAR_F_WAND | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'MACE', :cost => 8, :power => 2, :flags => CHAR_F_WAND | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'FLAIL', :cost => 10, :power => 2, :flags => CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'DAGGER', :cost => 8, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'GAUNTLET', :cost => 6, :power => 1, :flags => CHAR_F_WAND | CHAR_F_WARR | CHAR_F_BARB}]
      #armour
      ob[:page_2] = [{:name => 'HEAVY ARMOUR', :cost => 18, :power => 5, :flags => CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'CHAIN ARMOUR', :cost => 15, :power => 4, :flags => CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'LEATHER SKINS', :cost => 9, :power => 3, :flags => CHAR_F_WAND | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'HEAVY ROBE', :cost => 9, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'GOLD HELMET', :cost => 14, :power => 2, :flags => CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'HEADPIECE', :cost => 8, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'SHIELD', :cost => 6, :power => 3, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'TORCH', :cost => 6, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE | CHAR_F_WARR | CHAR_F_BARB}]
      #emporium
      ob[:page_3] = [{:name => 'NECRONOMICON', :cost => 20, :power => 4, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE},
                     {:name => 'SCROLLS', :cost => 15, :power => 3, :flags => CHAR_F_MAGE},
                     {:name => 'RING', :cost => 14, :power => 2, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE},
                     {:name => 'MYSTIC AMULET', :cost => 12, :power => 2, :flags => CHAR_F_WAND | CHAR_F_MAGE},
                     {:name => 'SASH', :cost => 10, :power => 3, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE},
                     {:name => 'CLOAK', :cost => 8, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE},
                     {:name => 'HEALING SALVE', :cost => 6, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE | CHAR_F_WARR | CHAR_F_BARB},
                     {:name => 'POTION', :cost => 6, :power => 1, :flags => CHAR_F_WAND | CHAR_F_CLER | CHAR_F_MAGE | CHAR_F_WARR | CHAR_F_BARB}]

      ob
    end

  end

end
