FactoryBot.define do
  factory :user do
    email { 'john@test.com' }
    password { 'some_password' }
  end
end
