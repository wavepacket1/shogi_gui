class Board < ApplicationRecord
    has_many :pieces, dependent: :destroy

    def to_sfen(include: nil)
        grid = Array.new(9) { Array.new(9, '') }

        pieces.each do |piece|
            x = piece.position_x 
            y = piece.position_y
            symbol = piece.piece_type
            symbol = "+#{symbol}" if piece.promoted?
            symbol = symbol.downcase if piece.owner == 'w' #後手の駒は小文字
            grid[y][x] = symbol
        end

        board_part = grid.map do |row|
            empty_count = 0
            row_sfen = ''

            row.each do |cell|
                if cell.blank?
                    empty_count += 1
                else
                    row_sfen += empty_count.to_s if empty_count > 0
                    empty_count = 0
                    row_sfen += cell
                end
            end
            row_sfen += empty_count.to_s if empty_count > 0
            row_sfen
        end.join('/')

        #手番
        player_to_move = 'b'

        #持ち駒(現段階ではなしを表す'-'を設定)
        pieces_in_hand = '-'

        #手数(現段階では1手目を表す'1'を設定)
        move_count = '1'

        "#{board_part} #{player_to_move} #{pieces_in_hand} #{move_count}"
    end
end
