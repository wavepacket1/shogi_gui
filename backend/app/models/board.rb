class Board < ApplicationRecord
    has_many :pieces, dependent: :destroy
    belongs_to :game

    def parse_sfen
        board_part, side, hand_part, move_number = sfen.split(" ")
        {
          board_array: parse_board(board_part),
          side: ,
          hand: parse_hand(hand_part),
          move_number: move_number.to_i
        }
    end

    private

    def parse_board(board_part)
        board_part.split("/").map { |row| parse_row(row) }
    end
    
    def parse_row(row)
        row.chars.each_with_object([]).with_index do |(char, row_arr), i|
            if char.match?(/\d/)
                row_arr.concat([nil] * char.to_i)
            elsif char == "+"
                validate_plus(row, i)
                row_arr << "+#{row[i + 1]}"
            else
                row_arr << char
            end
        end
    end
    
    def validate_plus(row, i)
        raise "Invalid sfen: '+' without a piece" if i + 1 >= row.size || !row[i + 1].match?(/[a-zA-Z]/)
    end
    
    def parse_hand(hand_part)
        return {} if hand_part == "-"
        hand_part.scan(/([a-zA-Z])(\d+)?/).each_with_object({}) do |(piece, count), hand|
            hand[piece] = count ? count.to_i : 1
        end
    end

    class << self 
        def convert_move_to_indices(board_array, move)
            step_map = ('a'..'i').to_a.zip(0..8).to_h
            from_line = 9 - move[0].to_i
            from_step = step_map[move[1]]
            to_line = 9 - move[2].to_i
            to_step = step_map[move[3]]
            [from_line, from_step, to_line, to_step]
        end
    
        def parse_move(move)
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

        def array_to_sfen(board_array, side, hand, move_number)
            board_part = generate_board_part(board_array)
            side_str = side
            hand_str = generate_hand_part(hand)
            move_number_str = move_number.to_s

            "#{board_part} #{side_str} #{hand_str} #{move_number_str}"
        end
    
        def create_next_board(parsed_data, move_info, board, game)
            board_array, hand, side, move_number = parsed_data.values_at(:board_array, :hand, :side, :move_number)
    
            Move.execute_move_or_drop(board_array, hand, side, move_info)
    
            next_side, next_move_number = update_game_state(side, move_number)
        
            create_board_record(board_array, hand, next_side, next_move_number, game)
        end
    
        private

        def generate_board_part(board_array)
            board_array.map do |row|
                row_to_sfen(row)
            end.join("/")
        end

        def row_to_sfen(row)
            row_str = ""
            empty_count = 0
            row.each do |cell|
                if cell.nil?
                    empty_count += 1
                else
                    row_str << empty_count.to_s if empty_count > 0
                    empty_count = 0
                    row_str << cell.to_s
                end
            end
            row_str << empty_count.to_s if empty_count > 0
            row_str
        end

        def generate_hand_part(hand)
            return '-' if hand.empty?
        
            generate_hand_pieces(hand, true) + generate_hand_pieces(hand, false)
        end

        def generate_hand_pieces(hand, sente)
            hand.select { |piece, _| sente ? piece == piece.upcase : piece == piece.downcase }
                .sort
                .map { |piece, count| count == 1 ? piece : "#{count}#{piece}" }
                .join
        end
    
        def create_board_record(board_array, hand, side, move_number, game)
            new_sfen = array_to_sfen(board_array, side, hand, move_number)
            create!(game_id: game.id, sfen: new_sfen)
        end
    
        def update_game_state(side, move_number)
            next_side = (side == 'b' ? 'w' : 'b')
            next_move_number = move_number + 1
            [next_side, next_move_number]
        end
    
        def convert_square_to_indices(sq)
            row_map = ('a'..'i').to_a.zip(0..8).to_h
            row = row_map[sq[1]]
            col = 9 - sq[0].to_i
            [row, col]
        end
    end
end
