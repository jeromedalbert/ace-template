require 'test_helper'

module CLI
  class InteractivePromptTest < Minitest::Test
    def test_prompt
      prompt =
        InteractivePrompt.new(
          [
            Option.new(name: 'option_1', description: 'Option 1 description'),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt)

      assert_output <<~EOS
        ‣ ⬡ option_1 - Option 1 description
          ⬡ option_2 - Option 2 description
      EOS
    end

    def test_movement
      prompt =
        InteractivePrompt.new(
          [
            Option.new(name: 'option_1', description: 'Option 1 description'),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt, keypresses: ['j'])

      assert_output <<~EOS
          ⬡ option_1 - Option 1 description
        ‣ ⬡ option_2 - Option 2 description
      EOS
    end

    def test_movement_wraps
      prompt =
        InteractivePrompt.new(
          [
            Option.new(name: 'option_1', description: 'Option 1 description'),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt, keypresses: %w[j j])

      assert_output <<~EOS
        ‣ ⬡ option_1 - Option 1 description
          ⬡ option_2 - Option 2 description
      EOS
    end

    def test_selection
      prompt =
        InteractivePrompt.new(
          [
            Option.new(name: 'option_1', description: 'Option 1 description'),
            Option.new(name: 'option_2', description: 'Option 2 description'),
            Option.new(name: 'option_3', description: 'Option 3 description')
          ]
        )

      selection = run_prompt(prompt, keypresses: [' ', 'j', ' ', ' ', 'j', ' '])

      assert_output <<~EOS
          ⬢ option_1 - Option 1 description
          ⬡ option_2 - Option 2 description
        ‣ ⬢ option_3 - Option 3 description
      EOS
      assert_equal({ 'option_1' => true, 'option_3' => true }, selection)
    end

    def test_unselected_option_with_values
      prompt =
        InteractivePrompt.new(
          [
            Option.new(
              name: 'option_1',
              description: 'Option 1 description',
              values: %w[value_a value_b]
            ),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt)

      assert_output <<~EOS
        ‣ ⬡ option_1 - Option 1 description
          ⬡ option_2 - Option 2 description
      EOS
    end

    def test_selected_option_with_values
      prompt =
        InteractivePrompt.new(
          [
            Option.new(
              name: 'option_1',
              description: 'Option 1 description',
              values: %w[value_a value_b]
            ),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt, keypresses: [' '])

      assert_output <<~EOS
        ‣ ⬢ option_1 - Option 1 description
                ⬢ value_a
                ⬡ value_b
          ⬡ option_2 - Option 2 description
      EOS
    end

    def test_option_values_movement
      prompt =
        InteractivePrompt.new(
          [
            Option.new(
              name: 'option_1',
              description: 'Option 1 description',
              values: %w[value_a value_b]
            ),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      run_prompt(prompt, keypresses: [' ', 'j'])

      assert_output <<~EOS.indent(2)
        ⬢ option_1 - Option 1 description
            ‣ ⬢ value_a
              ⬡ value_b
        ⬡ option_2 - Option 2 description
      EOS
    end

    def test_option_values_selection
      prompt =
        InteractivePrompt.new(
          [
            Option.new(
              name: 'option_1',
              description: 'Option 1 description',
              values: %w[value_a value_b]
            ),
            Option.new(name: 'option_2', description: 'Option 2 description')
          ]
        )

      selection = run_prompt(prompt, keypresses: [' ', 'j', 'j', ' '])

      assert_output <<~EOS.indent(2)
        ⬢ option_1 - Option 1 description
              ⬡ value_a
            ‣ ⬢ value_b
        ⬡ option_2 - Option 2 description
      EOS
      assert_equal({ 'option_1' => 'value_b' }, selection)
    end

    def test_exit
      app = mock
      prompt = InteractivePrompt.new(app: app)

      app.expects(:delete_created_app)

      assert_raises(SystemExit) { run_prompt(prompt, keypresses: ['q']) }
    end

    private

    Option = TemplateOptionParser::Option

    def run_prompt(prompt, keypresses: [])
      selected_options = nil
      TTY::Reader.any_instance.stubs(:read_keypress).returns(*keypresses, "\n")

      io = capture_io { selected_options = prompt.run }
      @output = TTY::Reader::Line.sanitize(io.first)

      selected_options
    end

    def assert_output(expected)
      assert_match expected, @output
    end
  end
end
