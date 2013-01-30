module DungeonOfDoom

  class DungeonGenerator

    def initialize
      #set up screen for the generator
      @ui = DungeonOfDoom::ScreenHandler.new(22,24)
      #draw the message/title box
      @ui.draw_box(20,5,1,1,
                   DungeonOfDoom::C_BLACK_ON_YELLOW,
                   DungeonOfDoom::C_WHITE_ON_RED)
      #draw the room box
      @ui.draw_box(17,17,2,6,
                   DungeonOfDoom::C_BLACK_ON_WHITE,
                   DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text("LEVEL GENERATOR",2,2)
      @ui.place_text("PRESS ? FOR HELP",2,4)

      #set up 15x15 room with the space character as the default floow
      @room = Array.new(15) { Array.new(15, DungeonOfDoom::CHAR_FLOOR)}
      #place initial cursor at top left corner of room box
      @cur_x = 0
      @cur_y = 0
      #store coordinates of where 'WAY IN' is (initially nil)
      @in_x = nil
      @in_y = nil
      #room save string. Store the levels (unlimited but should stick to 3 or 4)
      @levels = Array.new

      #initial starting level (intially zero)
      @current_level = 0
      #now update and display current level
      update_level
    end

    # Main entry point.  Loops until a valid key is pressed,  Then do the action
    def run
      begin
        display_cursor #show initial cursor
        #get input
        key = nil
        while true
          key = @ui.instr
          case key
          when '?'
            display_help
          when 'n','N'
            save_level
          when 'l','L'
            move_cursor(:right)
          when 'h','H'
            move_cursor(:left)
          when 'k','K'
            move_cursor(:up)
          when 'j','J'
            move_cursor(:down)
          when "0".."9"
            place_character(key)
          when 'q','Q'
            break if save_and_quit #return true if sucessful then exit loop
          else
            #ignore key pressed
          end
        end
      ensure
        @ui.cleanup_screen
      end
    end

    private

    # Display the help messages
    def display_help
      #set up the help message
      help_message = ["PRESS ANY KEY","TO MOVE J K H L","1 WALL  2 POTION",
                      "3 CHEST   4 IDOL*","5 WAY IN  6 EXIT","7 TRAP","8 SAFE PLACE",
                      "9 MONSTER", "0 TO ERASE","N FOR NEXT LEVEL","Q TO SAVE & EXIT"]
      @ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
      help_message.each do |msg|
        @ui.place_text(msg.ljust(18),2,5)
        @ui.input
      end
      @ui.place_text(" "*18,2,5) #18 spaces
    end

    # Cursor moving is in two steps, unset cursor at current position and
    # set the cursor at the new position.  Move the cursor either left,
    # right, up or down, and if cursor hits a boundry then don't change value.
    def move_cursor(direction)
      #reset the current square to orginal colour
      display_cursor(DungeonOfDoom::C_BLACK_ON_WHITE)

      #now move the cursor
      case direction
      when :left
        @cur_x -=1 if @cur_x > 0
      when :right
        @cur_x +=1 if @cur_x < 14
      when :up
        @cur_y -=1 if @cur_y > 0
      when :down
        @cur_y +=1 if @cur_y < 14
      else
        #unknown direction
      end

      #display the cursor at the new location
      display_cursor
    end

    # Display the cursor at the current position
    # Note, if current position is a space then, fool the square to look
    # like a cursor. @cur_x,@cur_y are room values, so need to convert
    # them to screen values by adding the initial starting position (3,7)
    # Colour can be overriden by passing a a colour
    def display_cursor(force_colour=nil)
      colour = force_colour || DungeonOfDoom::C_YELLOW_ON_RED
      @ui.set_colour(colour)
      @ui.place_text(@room[@cur_x][@cur_y], @cur_x+3, @cur_y+7)
    end

    # Given the number keyed (0 to 9), place the map character in the room and
    # redraw space where cursor is.  see MAP_TILES array in constants.rb file
    # for numeric mapping.  A special case arrised for 9 - Monster.  It will
    # randmonly select one of three monster characters.
    def place_character(key)
      index = 0
      if key == '9'  #monster, create a random monster
        random = Random.new
        index = random.rand(3)
      elsif key == '5' #save x,y of door location
        @in_x = @cur_x
        @in_y = @cur_y
      end
      @room[@cur_x][@cur_y] = DungeonOfDoom::MAP_TILES[key.to_i][index]

      #display the cursor to show new tile
      display_cursor
    end

    # The room data, entry door position and level number are serialised into
    # one line and stored in the level array.  The level data is placed col by
    # col into one line and the entry position and level are joined to the end
    # of this line.
    #
    # Entry position and level data could be more than 1 character
    # so convert to a string and right justify with '0'.  Two spaces for entry
    # and three for level.
    #
    # If no entry door has been set, then this method returns without saving.
    # A message is printed with the outcome.  If the save is successful, the
    # room and entry door position are reset and the level number is updated.
    def save_level
      message = "LEVEL SAVED!"
      if @in_x.nil?
        message = "ENTRY DOOR NEEDED!"
      else
        #save the level
        level_data = ""
        @room.each { |col| level_data << col.join } #serialize the room
        level_data << @in_x.to_s.rjust(2, "0") << @in_y.to_s.rjust(2, "0") << @current_level.to_s.rjust(2, "0")
        @levels << level_data
        #reset room, entry and increment level number
        @room = Array.new(15) { Array.new(15, DungeonOfDoom::CHAR_FLOOR) }
        @cur_x, @cur_y = 0, 0
        @in_x, @in_y = nil, nil
        @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
        update_level
        #redraw blank room
        @ui.set_colour(DungeonOfDoom::C_BLACK_ON_WHITE)
        @room.each_with_index do |col, x|
          col.each_with_index do |_, y|
            @ui.place_text(@room[x][y], x+3, y+7)
          end
        end
      end
      @ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
      @ui.place_text(message.ljust(18),2,5)
    end

    # Saves the levels to a level file and return sucess!
    # Ask the user for level file name and saves @levels to that file.
    #
    # If current_level doesn't have an idol or entry door then
    # don't quit and return fail.
    def save_and_quit
      message = if @in_x.nil?
        "ENTRY DOOR NEEDED!"
      elsif @room.detect {|col| col.join.include?(DungeonOfDoom::CHAR_IDOL)}.nil?
        "IDOL NEEDED"
      else
        ""
      end
      if message.empty?
        save_level
        #get file name
        @ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
        @ui.place_text("MAP NAME:".ljust(18),2,5)
        file_name = @ui.get_string(11,5)
        #create file
        File.open(file_name, "w") do |file|
          @levels.each {|level| file.puts level}
        end
        true
      else
        @ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
        @ui.place_text(message.ljust(18),2,5)
        false
      end
    end

    # Update the current level counter and display the new level number
    def update_level
      @current_level += 1
      @ui.place_text("THIS IS LEVEL: #@current_level".ljust(18) ,2,3)
    end
  end
end
