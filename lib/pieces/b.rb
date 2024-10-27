require_relative 'base_piece'

module Shogi
    module Pieces
        class B < Shogi::Pieces::BasePiece
            def initialize
                @promoted = false
                movement = []
                (1..8).each do |i|
                    movement << [i,i]
                    movement << [-i,i]
                    movement << [i,-i]
                    movement << [-i,-i]
                end
                super(movement)
            end
        end
    end
end