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
  			"9 MONSTER", "0 TO ERASE","S TO SAVE","X TO EXIT"]
  		#place initial cursor at top left corner of room box
  		@cur_x = 2
  		@cur_y = 7

        #now update and display current level
  		update_level
  	end

    # Main entry point.  Loops until a valid key is pressed,  Then do the action
    def run
    	begin
	    	#get input
	    	key = nil
	    	while key != 'x' && key != 'X'
	     	  key = @ui.instr
	     	  case key
	     	  when '?'
	     	  	display_help
	     	  end
	     	end
	    ensure
       	    @ui.cleanup_screen
       	end
    end

    # Display the help messages
    def display_help
    	@ui.set_colour(DungeonOfDoom::C_WHITE_ON_RED)
    	@help_message.each do |msg|
    		@ui.place_text(msg.ljust(18),2,5)
    		@ui.input
    	end
    	@ui.place_text(" "*18,2,5)
    end

    private

    def update_level
    	@current_level += 1
        @ui.place_text("THIS IS LEVEL: #{@current_level}".ljust(18) ,2,3)
    end
  end
end