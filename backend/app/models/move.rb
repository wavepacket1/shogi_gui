class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

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