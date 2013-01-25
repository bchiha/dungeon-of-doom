module DungeonOfDoom

  class ScreenHandler
    include Curses

    # Intialize the screen, setting base window size with width and height
    # Use entire screen if not set
    def initialize(width = nil, height = nil)
      #standard curses setup
      init_screen
      start_color
      init_colours
      clear
      cbreak
      noecho
      curs_set(0)

      #determine the screen size to center the main window horizontally
      screen_width, screen_height = [stdscr.maxx, stdscr.maxy]
      win_width, win_height = [width || screen_width, height || screen_height]
      pos_x = (screen_width - win_width) / 2
      @win = Window.new(win_height, win_width, 0, pos_x)

      #set up game window
      @win.keypad(true)
      @win.box(0,0)
      @win.timeout=0
    end

    # Given a colour constant (see above), change the colour
    def set_colour(colour_number)
      @win.attron(color_pair(colour_number))
    end

    # Draw text as position x,y
    def place_text(text, x, y)
      @win.setpos(y,x)
      @win.addstr(text)
    end

    # Draw box with or without border
    # width and height are the box dimensions and colour is its colour
    # start_x and start_y is the boxes top left corner
    # If border_colour is set then border will be drawn.
    # The box is drawn with the fill_character which is defaulted to space
    def draw_box(width, height, start_x, start_y, colour, border_colour=nil, fill_character=" ")
      border = border_colour || colour
      set_colour(border)
      place_text(fill_character*width, start_x, start_y)
      (height-2).times do |pos_y|
        set_colour(border)
        place_text(fill_character, start_x, start_y+pos_y+1)
        set_colour(colour)
        place_text(fill_character*(width-2), start_x+1, start_y+pos_y+1)
        set_colour(border)
        place_text(fill_character, start_x+width-1, start_y+pos_y+1)
      end
      set_colour(border)
      place_text(fill_character*width, start_x, start_y+height-1)
    end

    # Get keystroke from screen
    def input
      key = nil
      key = @win.getch while key.nil?
      key
    end

    # Get input from screen regardless of key pressed.  If no key pressed
    # then nil is returned.  This is useful to manage keystrokes within
    # the application
    def instr
      @win.getch
    end

    # Get input from the screen until return is pressed.  Then return the input
    # keyed.  This turns echo and the cursor on to give feed back on what is
    # typed.  Starting x,y location of the string need to be set
    def get_string(x,y)
      #show the cursor in input
      echo
      curs_set(1)
      key = nil
      input_str = ""
      @win.setpos(y,x)
      while key != "\n".ord  #converts CR to 10, the Ascii number for line feed, new line
        key = @win.getch
        input_str += key.to_s if key != "\n".ord
      end
      #hide the cursor and input
      noecho
      curs_set(0)
      #return the string
      input_str
    end

    # Clean up windows and exit cleanly
    def cleanup_screen
      @win.close
      close_screen
    end

    private

    # Set the initial colours to use. Use own colour definitions
    def init_colours
      init_pair(DungeonOfDoom::C_WHITE_ON_RED,COLOR_WHITE,COLOR_RED)
      init_pair(DungeonOfDoom::C_RED_ON_YELLOW,COLOR_RED,COLOR_YELLOW)
      init_pair(DungeonOfDoom::C_BLACK_ON_YELLOW,COLOR_BLACK,COLOR_YELLOW)
      init_pair(DungeonOfDoom::C_YELLOW_ON_WHITE,COLOR_YELLOW,COLOR_WHITE)
      init_pair(DungeonOfDoom::C_BLACK_ON_WHITE,COLOR_BLACK,COLOR_WHITE)
      init_pair(DungeonOfDoom::C_WHITE_ON_BLACK,COLOR_WHITE,COLOR_BLACK)
      init_pair(DungeonOfDoom::C_YELLOW_ON_RED,COLOR_YELLOW,COLOR_RED)
    end
  end
end
