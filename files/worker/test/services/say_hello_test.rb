require 'test_helper'

class SayHelloTest < ActiveSupport::TestCase
  test 'perform' do
    STDOUT.expects(:puts).with('Hello world!')

    SayHello.new.perform
  end
end
