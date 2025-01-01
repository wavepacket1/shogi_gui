module Pieces
    class P 
        class << self
            def move?(move_info, side, piece)
                dx = move_info[:to_col] - move_info[:from_col]
                dy = move_info[:to_row] - move_info[:from_row]
                
                # 歩は1マス前にのみ進める
                dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))
            end
        end
    end
end