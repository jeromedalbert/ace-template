FactoryBot.define do
  factory :user do
    email { 'john@doe.com' }
    password { 'some_password' }
  end
end
