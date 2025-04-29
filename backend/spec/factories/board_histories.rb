# frozen_string_literal: true

FactoryBot.define do
  factory :board_history do
    association :game
    sfen { "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0" }
    move_number { 0 }
    branch { "main" }
    move_sfen { nil }
  end
end 