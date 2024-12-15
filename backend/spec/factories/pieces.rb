FactoryBot.define do
  factory :piece do
    board { nil }
    position_x { 1 }
    position_y { 1 }
    type { "" }
  end
end
