module DungeonOfDoom

  class ScreenHandler
    include Curses

    # Define internal colour Constants
    C_YELLOW_ON_RED = 1
    C_RED_ON_YELLOW = 2
    C_BLACK_ON_YELLOW = 3
    C_YELLOW_ON_WHITE = 4

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

    def test
       set_colour(C_RED_ON_YELLOW)
       place_text(@win.maxy.to_s, 5,2)
       draw_box(19,5,1,1,C_BLACK_ON_YELLOW,C_YELLOW_ON_RED)
       draw_box(17,17,1,6,C_YELLOW_ON_WHITE,C_BLACK_ON_YELLOW)
       flash
       doupdate
       get_input
    end

    # Clean up windows and exit cleanly
    def end_game
      @win.close
      close_screen
    end

    private

    # Set the initial colours to use. Use own colour definitions
    def init_colours
      init_pair(C_YELLOW_ON_RED,COLOR_YELLOW,COLOR_RED)
      init_pair(C_RED_ON_YELLOW,COLOR_RED,COLOR_YELLOW)
      init_pair(C_BLACK_ON_YELLOW,COLOR_BLACK,COLOR_YELLOW)
      init_pair(C_YELLOW_ON_WHITE,COLOR_YELLOW,COLOR_WHITE)
    end

    def get_input
      key = nil
      key = @win.getch while key.nil?
      key
    end
  end
end
