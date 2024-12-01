class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

    validates :from_x, presence: true, inclusion: { in: 1..9 }
    validates :from_y, presence: true, inclusion: { in: 1..9 }
    validates :to_x, presence: true, inclusion: { in: 1..9 }
    validates :to_y, presence: true, inclusion: { in: 1..9 }
    validates :promotion, inclusion: { in: [true, false] }

    validates :validate_move_legality

    def to_sfen_move
        promotion_flag = promotion ? '+' : ''
        "+{from_x}#{from_y}#{promotion_flag}#{to_x}#{to_y}"
    end
end