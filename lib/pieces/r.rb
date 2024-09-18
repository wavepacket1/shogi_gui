module Shogi
    module Pieces
        class R < BasePiece
            def initialize
                movement = []
                (1..8).each do |i|
                    movement << [0,i]
                    movement << [0,-i]
                    movement << [i,0]
                    movement << [-i,0]
                end
                super(movement)
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