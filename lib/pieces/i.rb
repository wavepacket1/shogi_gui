require_relative 'base_piece'

module Shogi
    module Pieces
        class I < Shogi::Pieces::BasePiece
            def initialize
                super([[0, 1], [1, 1], [-1, 1], [1, 0], [-1, 0]], can_jump: false)
            end
        end
    end
end