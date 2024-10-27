require_relative 'validation'
require 'byebug'
require 'yaml' 

# YAMLファイルの読み込み
CONFIG = YAML.load_file(File.join(__dir__,'config/constants.yml'))

#定数の定義
HAND_INDEX_FIRST = CONFIG['HAND_INDEX_FIRST']
HAND_INDEX_SECOND = CONFIG['HAND_INDEX_SECOND']

# 持ち駒キーと対応する手駒インデックスのマッピング
PLAYER_HAND_INDEX = CONFIG['PLAYER_HAND_INDEX']
RELEASION_PIECE_AND_PROMOTION_PIECE = CONFIG['RELEASION_PIECE_AND_PROMOTION_PIECE'].freeze

module Shogi
    class Board
        # USIプロトコルの座標表示
        # 9a 8a 7a 6a 5a 4a 3a 2a 1a
        # 9b 8b 7b 6b 5b 4b 3b 2b 1b
        # 9c 8c 7c 6c 5c 4c 3c 2c 1c
        # 9d 8d 7d 6d 5d 4d 3d 2d 1d
        # 9e 8e 7e 6e 5e 4e 3e 2e 1e
        # 9f 8f 7f 6f 5f 4f 3f 2f 1f
        # 9g 8g 7g 6g 5g 4g 3g 2g 1g
        # 9h 8h 7h 6h 5h 4h 3h 2h 1h
        # 9i 8i 7i 6i 5i 4i 3i 2i 1i
        attr_reader :board
        def initialize
            @board = initial_board
            @turn = true # 先手番ならtrue, 後手番ならfalse
        end

        # 初期ボードの配置
        def initial_board
            [
                ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                [], # 先手の持ち駒
                []  # 後手の持ち駒
            ]
        end

        # ボードを表示するメソッド
        def display
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        # ボードを初期状態にリセットするメソッド
        def reset
            @board = initial_board
        end
    
        def move_for_usi_protocol(usi_protocol, move_direction, turn)
            #駒を成る場合
            if promotion_move?(usi_protocol)
                handle_promotion_move(usi_protocol, move_direction, turn)
            #持ち駒を打つ場合 
            elsif strike_move?(usi_protocol)
                handle_strike_move(usi_protocol, move_direction, turn)
            #通常の駒移動の場合
            else
                handle_normal_move(usi_protocol, move_direction, turn)
            end
        end
        # 手を実行するメソッド
        # move_protocol: 指し手の表記
        # 駒の移動元の位置と移動先の位置を並べて表記する(7g7f)
        # 駒が成る時は末尾に+をつける(8h2b+)
        # 持ち駒を打つ時は、最初の駒の種類を大文字で書き、それに*をつけて、次に打つ位置を表記する(P*7g)
        def move(move_protocol, turn)
            move_direction = turn_value(turn)
            move_for_usi_protocol(move_protocol, move_direction, turn)
        end

        private

        def promotion_move?(usi_protocol)
            usi_protocol.include?("+")
        end

        def strike_move?(usi_protocol)
            usi_protocol.include?("*")
        end

        def handle_promotion_move(usi_protocol, move_direction, turn)
            before_position, after_position = parse_usi_protocol(usi_protocol)
            before_coordinate = convert_to_board_coordinates(before_position)
            after_coordinate = convert_to_board_coordinates(after_position)
            return if !Validation.promotion_legal?(@board, before_coordinate, after_coordinate, @board[before_coordinate[0]][before_coordinate[1]], move_direction, turn)
            move_promotion_piece_for_usi(before_coordinate, after_coordinate, turn)
        end

        def handle_strike_move(usi_protocol, move_direction, turn)
            strike_piece = usi_protocol[0]
            strike_position = convert_to_board_coordinates(usi_protocol[2..3])
            #持ち駒を打つ際に合法手になっているかどうかを判定
            return if !Validation.strike_legal?(board, strike_position, strike_piece, move_direction, turn)
            @board[strike_position[0]][strike_position[1]] = strike_piece
            hand_index = turn ? HAND_INDEX_FIRST : HAND_INDEX_SECOND
            @board[hand_index].delete(strike_piece)
        end

        def handle_normal_move(usi_protocol, move_direction, turn)
            if(usi_protocol.length != 4)
                return "不正な入力です"
            end
            before_position, after_position = parse_usi_protocol(usi_protocol)
            before_coordinate = convert_to_board_coordinates(before_position)
            after_coordinate = convert_to_board_coordinates(after_position)
            unless Validation.move_legal?(@board, before_coordinate, after_coordinate, @board[before_coordinate[0]][before_coordinate[1]], move_direction, turn)
                raise "不正な手です"
            end
            move_piece_for_usi(before_coordinate, after_coordinate, turn) 
        end

        def usi_coordinate_alphabet_to_number(alphabet)
            alphabet.ord - 'a'.ord
        end

        def parse_usi_protocol(usi_protocol)
            before_position = usi_protocol[0..1]
            after_position = usi_protocol[2..3]
            [before_position,after_position]
        end

        def convert_to_board_coordinates(position)
            vertical = 9 - position[0].to_i
            horizontal = usi_coordinate_alphabet_to_number(position[1])
            [horizontal,vertical]
        end

        def move_piece_for_usi(before_coordinate,after_coordinate, turn)
            before_horizon, before_vertical = before_coordinate
            after_horizon, after_vertical = after_coordinate
            # 駒を取るロジック
            take_piece(@board[after_horizon][after_vertical], turn) if @board[after_horizon][after_vertical] 
            move_piece = @board[before_horizon][before_vertical]
            @board[before_horizon][before_vertical] = nil
            @board[after_horizon][after_vertical] = move_piece
        end

        def move_promotion_piece_for_usi(before_coordinate, after_coordinate, turn)
            before_horizon, before_vertical = before_coordinate
            after_horizon, after_vertical = after_coordinate
            # 駒を取るロジック
            take_piece(@board[after_horizon][after_vertical], turn) if @board[after_horizon][after_vertical] 
            # 成駒に変換
            move_piece = RELEASION_PIECE_AND_PROMOTION_PIECE.key(@board[before_horizon][before_vertical])
            @board[before_horizon][before_vertical] = nil
            @board[after_horizon][after_vertical] = move_piece
        end

        # 駒を取る処理
        def take_piece(opponent_piece, turn)
            hand_index = turn ? HAND_INDEX_FIRST : HAND_INDEX_SECOND
            transformed_piece = transform_piece(opponent_piece, turn)
            @board[hand_index].push(transformed_piece)
        end

        # 持ち駒から駒を打つ処理
        def strike_piece(move_protocol, move_direction)
            next_position = parse_next_position(move_protocol)
            piece = extract_piece(move_protocol)

            unless Validation::strike_piece_validate(piece, next_position, move_direction,@board,@turn)
                return
            end

            place_piece_on_board(piece, next_position)
            remove_piece_from_hand(move_protocol, piece)
        end

        # 駒を成りおよび持ち駒の所有者に応じて変換するメソッド
        def transform_piece(piece, turn)
            base_piece = Validation.promotion_piece?(piece) ? RELEASION_PIECE_AND_PROMOTION_PIECE[piece] : piece
            turn ? base_piece.upcase : base_piece.downcase
        end

        # 指定された駒が自分の駒かどうかを判定するメソッド
        def own_piece?(piece, turn)
            turn ? (piece =~ /[A-Z]/) : (piece =~ /[a-z]/)
        end

        # move_protocolから駒を抽出するメソッド
        def extract_piece(move_protocol)
            move_protocol[-1].to_s
        end

        # 持ち駒から駒を削除するメソッド
        def remove_piece_from_hand(move_protocol, piece)
            hand_key = move_protocol[0..1]
            hand_index = PLAYER_HAND_INDEX[hand_key]

            unless hand_index
                raise "不正な持ち駒キー: #{hand_key}"
            end

            hand = @board[hand_index]
            piece_index = hand.index(piece)
            unless piece_index
                raise "持ち駒に指定された駒が存在しません: #{piece}"
            end

            hand.delete_at(piece_index)
        end

        # move_protocolから次の位置を解析するメソッド
        def parse_next_position(move_protocol)
            row = move_protocol[3].to_i - 1
            col = 9 - move_protocol[2].to_i
            [row, col]
        end

        # move_protocolから現在位置と次位置を解析するメソッド
        def parse_positions(move_protocol)
            present_position = [move_protocol[1].to_i - 1, 9 - move_protocol[0].to_i]
            next_position = parse_next_position(move_protocol)
            [present_position, next_position]
        end

        # ターンに応じた移動方向を決定するメソッド
        def turn_value(turn)
            turn ? -1 : 1
        end

        # move_protocolが成りの動きかどうかを判定するメソッド
        def promotion_move?(move_protocol)
            move_protocol.length == 6
        end

        # ターンを切り替えるメソッド
        def switch_turn
            @turn = !@turn
        end

        # ボード上に駒を配置するメソッド
        def place_piece_on_board(piece, position)
            @board[position[0]][position[1]] = piece
        end
    end
end
