require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'normalizes email' do
    user = User.new(email: 'JOHN@TEST.COM ')
    assert_equal 'john@test.com', user.email
  end
end
