require_relative 'base_piece'

module Shogi
    module Pieces
        class G < Shogi::Pieces::BasePiece
            def initialize 
                super([[0, 1], [1, 1], [-1, 1], [1, 0], [-1, 0], [0, -1]])
            end
        end
    end
end