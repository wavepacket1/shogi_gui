# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    status { 'active' }
    mode { 'play' }
  end
end 