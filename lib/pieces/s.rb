module Shogi
    module Pieces
        class S < BasePiece
            def initialize
                super([[0, 1], [1, 1], [-1, 1], [1, -1], [-1, -1]])
            end

            def validate(board,present_position,next_position)
                validate_movement(board,present_position,next_position)
            end

            def can_move?(board,next_position)
                can_move_validate(board,next_position)
            end
        end
    end
end