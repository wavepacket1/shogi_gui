class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

    def to_sfen_move
        promotion_flag = promotion ? '+' : ''
        "+{from_x}#{from_y}#{promotion_flag}#{to_x}#{to_y}"
    end

    class << self
        def process_move(game, board, move_str)
            ActiveRecord::Base.transaction do 
                Validator.validate!(game, board, move_str)
            end
        rescue StandardError => e
            Rails.logger.error("Move processing failed: #{e.message}")
            raise
        end
    end
end