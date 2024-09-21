module Shogi
    module Pieces
        class B < BasePiece
            def initialize
                movement = []
                (1..8).each do |i|
                    movement << [i,i]
                    movement << [-i,i]
                    movement << [i,-i]
                    movement << [-i,-i]
                end
                super(movement)
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