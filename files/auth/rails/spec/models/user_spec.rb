require 'rails_helper'

describe User do
  it { should have_many :sessions }

  it { should validate_presence_of :email }
  it { should normalize(:email).from('JOHN@TEST.COM ').to('john@test.com') }

  it { should have_secure_password }
end
