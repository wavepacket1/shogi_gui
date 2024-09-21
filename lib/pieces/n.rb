module Shogi
    module Pieces
        class N < BasePiece
            def initialize
                super([[1,2],[-1,2]],can_jump: true)
            end

            def validate(board,present_position,next_position)
                validate_movement(board,present_position,next_position)
            end

            def can_move?(board,next_position)
                can_move_validation(board,next_position)
            end
        end
    end
end