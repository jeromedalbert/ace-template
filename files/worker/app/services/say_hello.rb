class SayHello < ApplicationJob
  def perform
    STDOUT.puts 'Hello world!'
  end
end
