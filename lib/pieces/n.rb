require_relative 'base_piece'

module Shogi
    module Pieces
        class N < Shogi::Pieces::BasePiece
            def initialize
                super([[1,2],[-1,2]],can_jump: true)
            end
        end
    end
end