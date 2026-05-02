FactoryBot.define do
  factory :banana do
    association :user
    name { 'MyString' }
    length { 1 }
    weight { 1 }
  end
end
