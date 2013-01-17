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
       	DungeonOfDoom::C_YELLOW_ON_WHITE,
       	DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.set_colour(DungeonOfDoom::C_BLACK_ON_YELLOW)
      @ui.place_text("LEVEL GENERATOR",2,2)
      @ui.place_text("PRESS ? FOR HELP",2,4)

      #initial starting level (intially zero)
		  @current_level = 0
  		#set up 15x15 room with the space character as the default floow
  		@room = Array.new(15) { Array.new(15, DungeonOfDoom::CHAR_FLOOR)}
  		#set up the help message
  		@help_message = ["PRESS ANY KEY","TO MOVE J K H L","1 WALL    2 VASE",
  			"3 CHEST   4 IDOL*","5 WAY IN  6 EXIT","7 TRAP","8 SAFE PLACE",
  			"9 MONSTER", "0 TO ERASE","S TO SAVE","Q TO EXIT"]
  		#place initial cursor at top left corner of room box
  		@cur_x = 0
  		@cur_y = 0
  		#store coordinates of where 'WAY IN' is (initially nil)
  		@in_x = nil
  		@in_y = nil
  		#room save string. Store up to 10 levels
  		@levels = Array.new(10)

        #now update and display current level
  		update_level
  	end

    # Main entry point.  Loops until a valid key is pressed,  Then do the action
    def run
    	begin
	    	#get input
	    	key = nil
	    	while key != 'q' && key != 'Q'
	     	  key = @ui.instr
	     	  case key
	     	  when '?'
	     	  	display_help
          when 'l','L'
            move_cursor(:right)
          when 'h','H'
            move_cursor(:left)
          when 'k','K'
            move_cursor(:up)
          when 'j','J'
            move_cursor(:down)
	     	  end
          display_cursor
	     	end
	    ensure
       	    @ui.cleanup_screen
       	end
    end

    private

    # Display the help messages
    def display_help
    	@ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
    	@help_message.each do |msg|
    		@ui.place_text(msg.ljust(18),2,5)
    		@ui.input
    	end
    	@ui.place_text(" "*18,2,5) #18 spaces
    end

    # Display the cursor at the current position
    # Note, if current position is a space then, fool the square to look
    # like a cursor. @cur_x,@cur_y are room values, so need to convert
    # them to screen values by adding the initial starting position (3,7)
    # Colour can be overriden by passing a a colour
    def display_cursor(force_colour=nil)
      colour = if @room[@cur_x][@cur_y] == CHAR_FLOOR
        DungeonOfDoom::C_WHITE_ON_BLACK
      else
        DungeonOfDoom::C_BLACK_ON_WHITE
      end
      colour = force_colour if force_colour
      @ui.set_colour(colour)
      @ui.place_text(@room[@cur_x][@cur_y], @cur_x+3, @cur_y+7)
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
      end
    end

    def save_level

    end

    # Update the current level counter and display the new level number
    def update_level
    	@current_level += 1
        @ui.place_text("THIS IS LEVEL: #{@current_level}".ljust(18) ,2,3)
    end
  end
end