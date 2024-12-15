module Pieces
    class P < BasePiece
        def initialize
            super([[0,1]])
        end

        def validate(board,present_position,next_position,move_direction)
            validate_movement(board,present_position,next_position,move_direction)
        end

        def can_move?(board,next_position)
            can_move_validation(board,next_position)
        end
    end
end