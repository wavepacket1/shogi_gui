require_relative 'base_piece'

module Shogi
    module Pieces
        class L < Shogi::Pieces::BasePiece
            def initialize
                movement = []
                (1..8).each do |i|
                    movement << [0,i]
                end
                super(movement)
            end
        end
    end
end