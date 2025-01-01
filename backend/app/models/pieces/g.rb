module Pieces
    class G
        class << self
            def move?(move_info, side)
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = move_info[:to_row] - move_info[:from_row]
                
                if side == 'b'
                    (dx == 0 && dy == -1) ||  # 前
                    (dx == 1 && dy == -1) ||  # 斜め前
                    (dx == 1 && dy == 0) ||   # 横
                    (dx == 0 && dy == 1)      # 後ろ
                else
                    (dx == 0 && dy == 1) ||   # 前
                    (dx == 1 && dy == 1) ||   # 斜め前
                    (dx == 1 && dy == 0) ||   # 横
                    (dx == 0 && dy == -1)     # 後ろ
                end
            end
        end
    end
end