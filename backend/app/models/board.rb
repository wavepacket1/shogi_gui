class Board < ApplicationRecord
    has_many :pieces, dependent: :destroy
    belongs_to :game

    def parse_sfen 
        parts = sfen.split(" ")
        board_part = parts[0]
        side = parts[1]
        hand_part = parts[2]
        move_number = parts[3].to_i

        rows = board_part.split("/")
        board_array = rows.map do |row|
            row_arr = []
            chars = row.chars
            i = 0
            while i < chars.size
                c = chars[i]
                if c.match?(/\d/)
                    row_arr.concat(Array.new(c.to_i, nil))
                    i += 1
                elsif c == '+'
                    raise "Invalid sfen" if i == chars.size - 1
                    piece = '+' + chars[i + 1]
                    row_arr << piece
                    i += 2
                else
                    row_arr << c
                    i += 1
                end
            end
            row_arr
        end

        hand_hash =  parse_hand(hand_part)

        {
            board_array: board_array,
            side: side,
            hand: hand_hash,
            move_number: move_number
        }
    end

    def self.convert_move_to_indices(board_array, move)
        step_map = ('a'..'i').to_a.zip(0..8).to_h
        from_line = 9 - move[0].to_i
        from_step = step_map[move[1]]
        to_line = 9 - move[2].to_i
        to_step = step_map[move[3]]
        [from_line, from_step, to_line, to_step]
    end

    def self.parse_move(move)
        if move.include?('*')
            piece, rest = move.split('*')
            to_row, to_col = convert_square_to_indices(rest)
            { type: :drop, piece: piece, to_row: to_row, to_col: to_col }
        else
            promoted = move.end_with?('+')
            move_str = promoted ? move[0..-2] : move
            from_square = move_str[0..1]
            to_square = move_str[2..3]

            from_row, from_col = convert_square_to_indices(from_square)
            to_row, to_col = convert_square_to_indices(to_square)

            { type: :move, from_row: from_row, from_col: from_col, to_row: to_row, to_col: to_col, promoted: promoted }
        end
    end

    def self.array_to_sfen(board_array, side, hand, move_number)
        # 1. 盤面部分を生成
        rows = board_array.map do |row|
            row_str = ""
            empty_count = 0
            row.each do |cell|
                if cell.nil?
                    empty_count += 1
                else
                    # 空マスが溜まっていれば出力
                    if empty_count > 0
                        row_str << empty_count.to_s
                        empty_count = 0
                    end
                    # cellは'P'や'+P'など
                    row_str << cell.to_s
                end
            end
            # 行末に空マスが残っていれば出力
            row_str << empty_count.to_s if empty_count > 0
            row_str
        end
        board_part = rows.join("/")
    
        # 2. 手番を文字列化 (sideは 'b'か'w')
        side_str = side
    
        # 3. 持ち駒を文字列化
        # handは { 'R' => 2, 'B' => 1, 'p' => 3 } のようなハッシュを想定
        # 大文字は先手の駒、 小文字は後手の駒を示す
        hand_str = if hand.empty?
            '-'
        else
            # 先手の持ち駒（大文字）を先に処理
            sente_pieces = hand.select { |piece, _| piece == piece.upcase }.sort.map do |piece, count|
                count == 1 ? piece : "#{count}#{piece}"
            end

            # 後手の持ち駒（小文字）を後に処理
            gote_pieces = hand.select { |piece, _| piece == piece.downcase }.sort.map do |piece, count|
                count == 1 ? piece : "#{count}#{piece}"
            end

            # 先手と後手の持ち駒を連結
            (sente_pieces + gote_pieces).join
        end
    
        # 4. 手数を文字列化
        move_number_str = move_number.to_s
    
        # 最終的なSFEN: "<board> <side> <hand> <move_number>"
        "#{board_part} #{side_str} #{hand_str} #{move_number_str}"
    end

    def self.parse_board_data(board)
        parsed_data = board.parse_sfen
        {
          board_array: parsed_data[:board_array],
          side: parsed_data[:side],
          hand: parsed_data[:hand] || {},
          move_number: parsed_data[:move_number]
        }
    end

    private 

    def self.convert_square_to_indices(sq)
        row_map = ('a'..'i').to_a.zip(0..8).to_h
        row = row_map[sq[1]]
        col = 9 - sq[0].to_i
        [row, col]
    end

    def parse_hand(hand_str)
        return {} if hand_str == '-'

        hand_hash = {}
        i = 0
        while i < hand_str.size
            # 数字から始まる場合の処理
            count = 0
            while i < hand_str.size && hand_str[i] =~ /\d/
                count = count * 10 + hand_str[i].to_i
                i += 1
            end
            count = 1 if count == 0  # 数字がない場合は1個

            # 駒の種類を取得
            piece = hand_str[i]
            hand_hash[piece] = count
            i += 1
        end
        hand_hash
    end
end
