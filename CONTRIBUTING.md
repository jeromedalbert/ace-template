If you're interested in contributing to Ace Template, that's awesome!
We'd love your help.

## Reporting an issue

Feel free to report bugs and feature requests.

## Contributing to the code

The entry point of this project is [`template.rb`](template.rb), which is a Rails
[application template](https://guides.rubyonrails.org/rails_application_templates.html)
called when doing `rails new myapp -m /path/to/template.rb`. The template makes
heavy use of [actions](https://www.rubydoc.info/gems/thor/Thor/Actions) from
the [Thor](https://github.com/rails/thor) gem, and has custom actions and
helpers of its own in [`lib/helpers`](lib/helpers). To prevent `template.rb`
from growing too big, most of the actual work happens in [`lib/recipes`](lib/recipes)
files. Finally, the [`files`](files) folder contains files that may be copied
or inserted into the destination app.

Rails template development has its own quirks, so we recommend bookmarking the
following resources for reference:

- [Rails Application Templates](https://edgeguides.rubyonrails.org/rails_application_templates.html)
  Rails guide
- [Creating and Customizing Rails Generators & Templates](https://guides.rubyonrails.org/generators.html)
  Rails guide, particularly the "Application Templates" and "Rails Generators
  API" sections
- [Thor actions](https://www.rubydoc.info/gems/thor/Thor/Actions) API doc
- [Rails Generator Actions](https://api.rubyonrails.org/v7.1.3.2/classes/Rails/Generators/Actions.html)
  API doc

### Installing dependencies

After checking out the repo, run:

    bundle install

### Manually trying your local changes

You can run the template locally:

    rails new myapp -m /path/to/repo/template.rb

### Running Tests

You can run linters and unit tests in one go:

    bin/rake

Or to only run unit tests:

    bin/rake test:unit

Or to run linters, unit tests, and the main end-to-end test (useful to quickly
check that you didn't badly break the happy path):

    bin/rake test:smoke

To run an individual test file, for example `test/template_test.rb`, you can use:

    bin/test test/template_test.rb

And to run an individual test method named `test_template` within a test file, you can use:

    bin/test test/template_test.rb -n test_template

You can also run all test methods named `test_template`:

    bin/test -n test_template

If you need to tweak an end-to-end test but do not need a whole app to be recreated,
you can reuse the previously created app for significant speedups:

    REUSE_APP=1 bin/test -n test_template

Finally, if you decide to run all end-to-end tests on your local, run the following:

    bin/rake test:end_to_end

Some of them need to have postgres, mysql, and redis running.

### Linting

Code linting and formatting is done with Rubocop and SyntaxTree.

You can lint with:

    bin/rake lint

And you can format and autocorrect with:

    bin/rake format

### Submitting a pull request

New features should be coupled with tests.

Please note that if you are adding a new template option, you will probably
need to change or add an end-to-end test. Since these tests can be trickier,
maintainers may be able to help.

Once all your tests are passing and your code is linted, you are ready to
submit a pull request!
