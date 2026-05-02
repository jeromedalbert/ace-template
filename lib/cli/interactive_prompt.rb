module CLI
  class InteractivePrompt
    def initialize(available_options = [], app: nil)
      @available_options = available_options
      @app = app

      @selected_options = HashWithIndifferentAccess.new
      @finished = false
      @current_option_index = 0
      @current_suboption_index = nil
    end

    def run
      setup_tty_gems
      clear_screen

      until @finished
        draw_prompt
        key = read_keypress
        handle_keypress(key)
      end

      @selected_options
    end

    private

    def setup_tty_gems
      %w[tty-reader tty-cursor].each do |gem_name|
        require gem_name
      rescue LoadError
        system("gem install #{gem_name}") or exit(1)
        Gem.clear_paths
        require gem_name
      end
    end

    def clear_screen
      print TTY::Cursor.clear_screen
      print TTY::Cursor.move_to(0, 1)
    end

    def draw_prompt
      clear_prompt if @prompt

      @prompt = <<~EOS
        Select the options you want to enable:
        #{gray('(Use ↑/↓ or j/k to navigate, Space to select/deselect, and Enter to finish)')}

        #{options_text}

      EOS

      puts @prompt
    end

    def clear_prompt
      print TTY::Cursor.up(@prompt.lines.count)
      print TTY::Cursor.clear_screen_down
    end

    def gray(text)
      "\e[90m#{text}\e[0m"
    end

    def options_text
      @available_options
        .map
        .with_index { |option, option_index| option_text(option, option_index) }
        .join("\n")
    end

    def option_text(option, option_index)
      text = +''

      option_is_current = option_index == @current_option_index && @current_suboption_index.nil?
      prefix = option_is_current ? yellow('‣ ') : '  '
      checkbox = selected?(option) ? '⬢' : '⬡'
      text << "#{prefix}#{checkbox} #{option.name} - #{option.description}"

      if selected?(option) && option.values&.any?
        option.values.each_with_index do |suboption_value, suboption_index|
          text << "\n" + suboption_text(suboption_value, suboption_index, option, option_index)
        end
      end

      text
    end

    def yellow(text)
      "\e[33m#{text}\e[0m"
    end

    def selected?(option)
      @selected_options.key?(option.name)
    end

    def suboption_text(suboption_value, suboption_index, option, option_index)
      suboption_is_current =
        option_index == @current_option_index && suboption_index == @current_suboption_index
      suboption_is_selected = suboption_value == selected_value(option)

      prefix = suboption_is_current ? "      #{yellow('‣ ')}" : '        '
      checkbox = suboption_is_selected ? '⬢' : '⬡'

      "#{prefix}#{cyan(checkbox)} #{suboption_value}"
    end

    def selected_value(option)
      @selected_options[option.name]
    end

    def cyan(text)
      "\e[36m#{text}\e[0m"
    end

    def read_keypress
      @reader ||= TTY::Reader.new(interrupt: -> { exit_prompt })

      @reader.read_keypress
    end

    def exit_prompt
      @app&.delete_created_app
      exit
    end

    def handle_keypress(key)
      case key
      when 'j', "\e[B"
        navigate_down
      when 'k', "\e[A"
        navigate_up
      when ' '
        toggle_selection
      when "\r", "\n"
        @finished = true
      when 'q', "\e"
        exit_prompt
      end
    end

    def navigate_down
      current_option = @available_options[@current_option_index]

      if @current_suboption_index.nil?
        if selected?(current_option) && current_option.values&.any?
          @current_suboption_index = 0
        else
          @current_option_index = (@current_option_index + 1) % @available_options.length
        end
      elsif @current_suboption_index == current_option.values.length - 1
        @current_suboption_index = nil
        @current_option_index = (@current_option_index + 1) % @available_options.length
      else
        @current_suboption_index += 1
      end
    end

    def navigate_up
      if @current_suboption_index.nil?
        @current_option_index = (@current_option_index - 1) % @available_options.length
      elsif @current_suboption_index == 0
        @current_suboption_index = nil
      else
        @current_suboption_index -= 1
      end
    end

    def toggle_selection
      current_option = @available_options[@current_option_index]

      if @current_suboption_index.nil?
        toggle_option(current_option)
      else
        select_suboption(current_option)
      end
    end

    def toggle_option(option)
      if selected?(option)
        @selected_options.delete(option.name)
      else
        @selected_options[option.name] = option.default_value
      end
    end

    def select_suboption(option)
      @selected_options[option.name] = option.values[@current_suboption_index]
    end
  end
end
