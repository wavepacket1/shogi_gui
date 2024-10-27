require_relative 'base_piece'

module Shogi
    module Pieces
        class P < Shogi::Pieces::BasePiece
            def initialize
                super([[0,1]])
            end
        end
    end
end