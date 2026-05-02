# Ace Template

A Rails application template to generate full-featured web apps fast:

- ⚡️ Go from `rails new` to deployed in less than 5 minutes.
  Demos: [self-hosted server](https://www.youtube.com/watch?v=kCXugP63Cqc) |
  [Fly.io](https://www.youtube.com/watch?v=2PsQQIbSsg0) |
  [Heroku](https://www.youtube.com/watch?v=iY_kVYGbbRk).
- ✍️ Automated, yet looks handcrafted. Thoughtful code diffs are applied in just the right places.
- 🕹️ Use interactive mode or command-line options for extra customization.
- 🔀 Use carefully curated defaults or the omakase default Rails way.
- 🔄 Designed to keep up with future versions of Rails. Tested daily against Rails `main`.

Ship your idea in record time, or learn how modern Rails 8+ apps are structured
and deployed. See [list of features](#features).

<br>

[![Screenshot of an app generated with Ace Template](https://raw.githubusercontent.com/jeromedalbert/files/main/ace-template/generated_app.png)](https://www.youtube.com/watch?v=kCXugP63Cqc)

## Usage

To create a basic app:

```bash
rails new myapp -m https://raw.githubusercontent.com/jeromedalbert/ace-template/stable/template.rb
```

It gets more interesting with options! You can choose template options
[interactively](https://raw.githubusercontent.com/jeromedalbert/files/main/ace-template/interactive_mode.png)
with `-i`:

```bash
rails new myapp -i -m https://raw.githubusercontent.com/jeromedalbert/ace-template/stable/template.rb
```

Or you can pass template options manually with `-o` (see [`-o help`](template.rb#L17)
for details). Rails options are also supported. For example, to create an app
with an example "Banana" resource and styled with Tailwind:

```bash
rails new myapp -o banana --css tailwind \
  -m https://raw.githubusercontent.com/jeromedalbert/ace-template/stable/template.rb
```

#### Pro-tip

To make commands shorter, you can add this function to your shell config (like
`~/.bashrc` or `~/.zshrc`):

```bash
rn() {
  rails new $1 -m https://raw.githubusercontent.com/jeromedalbert/ace-template/stable/template.rb ${@:2}
}
```

The previous example can now be shortened to `rn myapp -o banana --css tailwind`.

## Features

#### General

- Easy-to-follow instructions to deploy with [Kamal](https://kamal-deploy.org/),
  [Fly.io](https://fly.io/), or [Heroku](https://www.heroku.com/). Most
  instructions are copy-pasteable and can be found in the generated project Readme.
- Supports SQLite, Postgres, and MySQL databases.
- Supports the [Tailwind](https://tailwindcss.com/) and [Bootstrap](https://getbootstrap.com/)
  CSS frameworks, with default styles and HTML boilerplate that are ready to go.
- Each configuration step has its own commit, so you can see exactly how
  everything is set up.
- All generated code has thoughtful corresponding tests.
- Uses single quotes by default. Double quotes are supported as an option.
- Supports most `rails new` options like `--api`, `--skip-*`, `--main`,
  `--edge`, etc.

#### Options

- `banana`: scaffolds an example "Banana" resource for quick demos or as a
  starting point.
- `authentication`: adds authentication that is ready to go with login
  **and signup** pages, either with
  [Rails authentication](https://guides.rubyonrails.org/security.html#authentication)
  or [Devise](https://github.com/heartcombo/devise).
- `omakase`: uses Rails [omakase](https://rubyonrails.org/doctrine#omakase)
  defaults instead of Ace Template's defaults.
- `solid-dev`: configures [Solid Cable](https://github.com/rails/solid_cable),
  [Solid Cache](https://github.com/rails/solid_cache),
  and [Solid Queue](https://github.com/rails/solid_queue) to work in development.
- `worker`: removes web code, for apps like bots or scheduled scripts that do
  not need to be accessible with a web page.
- `errors`: adds an error monitoring service (either [Rollbar](https://rollbar.com/)
  or [Sentry](https://sentry.io/)).
- `pundit`: adds [Pundit](https://github.com/varvet/pundit) authorization.
- `redis`: adds Redis.
- `vcr`: adds the [VCR](https://github.com/vcr/vcr) gem to record test HTTP requests.

See [`-o help`](template.rb#L17) for the full list of options.

Options can **synergize** with each other. For example if both `banana` and
`authentication` are selected, bananas will belong to a user and logged in users
will only have access to their own bananas.

#### Default gems

- `IRB` and ruby `debug` are kept as defaults for interactive Ruby sessions.
  This combo now works just as well as the old Pry gems.
  [Amazing Print](https://github.com/amazing-print/amazing_print) is used for
  pretty printing and is a modern successor to Awesome Print that works with
  ruby `debug` sessions and Rails 8.2+.
- [Solid Cable](https://github.com/rails/solid_cable),
  [Solid Cache](https://github.com/rails/solid_cache),
  and [Solid Queue](https://github.com/rails/solid_queue) are kept as great
  defaults that can get you pretty far.
- [Rubocop](https://github.com/rubocop/rubocop) for linting and
  [SyntaxTree](https://github.com/ruby-syntax-tree/syntax_tree) for
  auto-formatting that looks good.
  [Standard](https://github.com/standardrb/standard) is also used as a
  collection of sensible Rubocop defaults that are further customized to fit
  Ace Template's own style.
- [RSpec](https://github.com/rspec/rspec-rails) tests by default.
  [Rails test cases](https://guides.rubyonrails.org/testing.html#writing-your-first-test)
  (backed by [Minitest](https://github.com/minitest/minitest)) are supported as
  an option.
- [Dotenv](https://github.com/bkeepers/dotenv) as a simple way to manage
  secrets.
  [Rails credentials](https://guides.rubyonrails.org/security.html#custom-credentials)
  are supported as an option.
- [FactoryBot](https://github.com/thoughtbot/factory_bot) for test data.
  [Rails fixtures](https://guides.rubyonrails.org/testing.html#fixtures) are
  supported as an option.
- [Spring](https://github.com/rails/spring) to run Rails commands and tests
  instantly on your local.
- [Lograge](https://github.com/roidrage/lograge) to make production logs simple
  and easy to read.

If you prefer to stick to Rails defaults, use the `omakase` template option.

## Why Ace Template?

I made most of this template in the pre-AI era for my personal use.
I think it is still relevant today, as it provides a solid foundation designed
with care by a human. It is predictable, token-free, and the generated app
becomes a mini harness of sorts that leads by example.

I recently added some finishing touches and open-sourced the project, in the
hope that some people find it useful as a productivity or learning tool.

A goal of this template is to be simple and to the point. I wanted it to run
via the familiar `rails new` command with no extra dependencies. It provides
extra options, but this is not a heavier SaaS starter kit. It's just plain
Rails, with some sprinkles!

## Contributing

Bug reports and pull requests are welcome! See [guide to contributing](CONTRIBUTING.md)
for more information.

## License

The project is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ace Template project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](CODE_OF_CONDUCT.md).

<br><br>
<div align="center">
  <a href="#ace-template">
    <img src="https://raw.githubusercontent.com/jeromedalbert/files/main/ace-template/cards.png" width="150" alt="Ace Template"/>
  </a>
</div>
