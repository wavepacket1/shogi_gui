require_relative 'base_piece'

module Shogi
    module Pieces
        class U < Shogi::Pieces::BasePiece
            def initialize
                movement = []
                (1..8).each do |i|
                    movement << [i, i]
                    movement << [-i, i]
                    movement << [i, -i]
                    movement << [-i, -i]
                end
                movement.concat([[0, 1], [1, 0], [0, -1], [-1, 0], [1, 1], [1, -1], [-1, 1], [-1, -1]])
                super(movement)
            end
        end
    end
end