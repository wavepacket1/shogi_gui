class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

    def to_sfen_move
        promotion_flag = promotion ? '+' : ''
        "+{from_x}#{from_y}#{promotion_flag}#{to_x}#{to_y}"
    end
end