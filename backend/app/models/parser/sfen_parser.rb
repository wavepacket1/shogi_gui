class Parser::SfenParser
    class << self 
        def parse(sfen)
            board_part, side, hand_part, move_number = sfen.split(" ")
            {
                board_array: parse_board(board_part),
                side: ,
                hand: parse_hand(hand_part),
                move_number: move_number.to_i
            }
        end

        def array_to_sfen(board_array, side, hand, move_number)
            board_part = generate_board_part(board_array)
            side_str = side
            hand_str = generate_hand_part(hand)
            move_number_str = move_number.to_s

            "#{board_part} #{side_str} #{hand_str} #{move_number_str}"
        end

        private

        def generate_board_part(board_array)
            board_array.map do |row|
                row_to_sfen(row)
            end.join("/")
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

        def parse_board(board_part)
            board_part.split("/").map { |row| parse_row(row) }
        end

        def parse_hand(hand_part)
            return {} if hand_part == "-"
            hand_part.scan(/([a-zA-Z])(\d+)?/).each_with_object({}) do |(piece, count), hand|
                hand[piece] = count ? count.to_i : 1
            end
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
    end
end