# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :board_history
    content { "テストコメント" }
  end
end 