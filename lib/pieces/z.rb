require_relative 'base_piece'

module Shogi
    module Pieces 
        class Z < Shogi::Pieces::BasePiece
            def initialize
                movement = []
                (1..8).each do |i|
                    movement << [0, i]
                    movement << [0, -i]
                    movement << [i, 0]
                    movement << [-i, 0]
                end
                movement.concat([[1, 1], [1, -1], [-1, 1], [-1, -1]])
                super(movement)
            end
        end
    end
end