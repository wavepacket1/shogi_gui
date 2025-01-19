class Validator
    class << self
        # 合法手かどうかを判定する
        def legal?(parsed_data, move_info, game)
            board_array = parsed_data[:board_array]
            side = parsed_data[:side]

            return false unless basic_legal_move?(board_array, side, move_info)
            
            # 王手放置のチェック
            simulated_board = simulate_move(board_array, move_info)
            return false if in_check?(simulated_board, side)

            # 打ち歩詰めのチェック
            return false if pawn_drop_mate?(board_array, side, move_info)

            board_history = Board.where(game_id: game.id).order(created_at: :desc).all

            # 連続王手の判定
            return false if perpetual_check?(simulated_board, side, board_history, move_info)
    
            # 千日手の判定
            return false if repetition_draw?(simulated_board, board_history, move_info)
            
            true
        end

        def legal_move?(board_array, side, move_info)
            from_piece = Piece.fetch_piece(board_array, move_info[:from_row], move_info[:from_col])
            return false unless Piece.valid_from_piece?(from_piece, side)

            to_piece = Piece.fetch_piece(board_array, move_info[:to_row], move_info[:to_col])
            return false unless Piece.valid_to_piece?(to_piece, side)
    
            piece_type = from_piece.upcase
            piece_class = Piece.get_piece_class(piece_type)

            piece_type.start_with?('+') ? piece_class.promoted_move?(move_info, board_array, side) : piece_class.move?(move_info, board_array, side)
        end

        def legal_drop?(board_array, side, move_info)
            piece_type = move_info[:piece].upcase
            to_row = move_info[:to_row]
            to_col = move_info[:to_col]

            return false unless Piece.drop_target_empty?(board_array, to_row, to_col)
            return false if piece_type == 'P' && validate_no_pawn_in_column?(board_array, to_col, side)
            return false if drop_restriction_violation?(piece_type, to_row, side)

            true
        end

        def pawn_drop_mate?(board_array, side, move_info)
            # 打ち歩詰めのチェック
            return false unless move_info[:type] == :drop && move_info[:piece].upcase == 'P'

            simulated_board = simulate_move(board_array, move_info)
            opponent_side = side == 'b' ? 'w' : 'b'

            return false unless in_check?(simulated_board, side)

            opponent_moves = generate_all_legal_moves(simulated_board, opponent_side)
            opponent_moves.empty?
        end

        def is_checkmate?(sfen)
            board_array = Parser::SfenParser.parse(sfen)[:board_array]
            hands = Parser::SfenParser.parse(sfen)[:hand]
            side = Parser::SfenParser.parse(sfen)[:side]
            return false unless in_check?(board_array, side)

            # 王手を回避する手があるかチェック
            return false unless check_moves(board_array, side)
            # 持ち駒を使って王手を回避する手があるかチェック
            return false unless check_hands(board_array, side, hands)
            return true
        end

        #　現在の局面で自陣の王が王手かどうかを判定する
        def in_check?(board_array, side)
            king_pos = find_king(board_array, side)
            return true unless king_pos # 王がない場合は王手とみなす
    
            opponent_side = side == 'b' ? 'w' : 'b'
            
            board_array.each_with_index do |row, from_row|
                row.each_with_index do |piece, from_col|
                    next if piece.nil?
                    next if piece_owner(piece) != opponent_side
        
                    move_info = {
                        type: :move,
                        from_row: from_row,
                        from_col: from_col,
                        to_row: king_pos[0],
                        to_col: king_pos[1]
                    }
        
                    piece_type = piece.gsub(/^\+/, '').upcase
                    piece_class = Piece.get_piece_class(piece_type)
                    
                    if piece.start_with?('+')
                        return true if piece_class.promoted_move?(move_info, board_array, opponent_side)
                    else
                        return true if piece_class.move?(move_info, board_array, opponent_side)
                    end
                end
            end
            false
        end

        # 次の手で敵陣の王が王手になるかどうかを判定する
        def will_check?(board_array, side, move_info)
            opponent_king_pos = find_king(board_array, side == 'b' ? 'w' : 'b')
            return false unless opponent_king_pos

            piece_class = Piece.get_piece_class(move_info[:piece_type])
        
            if move_info[:piece_type].start_with?('+')
                piece_class.promoted_move?(move_info.merge(to_row: opponent_king_pos[0], to_col: opponent_king_pos[1]), board_array, side)
            else
                piece_class.move?(move_info.merge(to_row: opponent_king_pos[0], to_col: opponent_king_pos[1]), board_array, side)
            end
        end

        def check_moves(board_array, side)
            board_array.each_with_index do |row, i|
                row.each_with_index do |piece, j|
                    next if piece.nil? || piece_owner(piece) != side

                    (-8..8).each do |dx|
                        (-8..8).each do |dy|
                            next if dx == 0 && dy == 0
                            to_row = i + dx
                            to_col = j + dy
                            next unless to_row.between?(0, 8) && to_col.between?(0, 8)

                            move_info = {
                                type: :move, 
                                from_row: i,
                                from_col: j,
                                to_row: to_row, 
                                to_col: to_col
                            }

                            if basic_legal_move?(board_array, side, move_info)
                                #移動後も王手が続いているかチェック
                                simulated_board = simulate_move(board_array, move_info)
                                return false unless in_check?(simulated_board, side)
                            end
                        end
                    end
                end
            end
            return true
        end

        def check_hands(board_array, side, hands)
            # 手番に応じて持ち駒をフィルタリング
            relevant_hands = if side == 'w'
                                hands.select { |piece, _| piece =~ /[a-z]/ }
                            else
                                hands.select { |piece, _| piece =~ /[A-Z]/ }
                            end

            relevant_hands.each do |piece, count|
                next if count == 0

                (0..8).each do |i|
                    (0..8).each do |j|
                        next unless board_array[i][j].nil?

                        move_info = {
                            type: :drop,
                            piece: piece,
                            to_row: i,
                            to_col: j
                        }

                        if basic_legal_move?(board_array, side, move_info)
                            #打った後も王手が続いているかチェック
                            simulated_board = simulate_move(board_array, move_info)
                            return false unless in_check?(simulated_board, side)
                        end
                    end
                end
            end
            return true
        end

        private 

        def generate_all_legal_moves(board_array, side)
            moves = [ ]

            board_array.each_with_index do |row, i|
                row.each_with_index do |piece, j|
                    next if piece.nil? || piece_owner(piece) != side

                    # 8方向の移動をチェック
                    (-8..8).each do |dx|
                        (-8..8).each do |dy|
                            next if dx == 0 && dy == 0

                            to_row = i + dx
                            to_col = j + dy

                            next unless to_row.between?(0, 8) && to_col.between?(0, 8)

                            move_info = {
                                type: :move,
                                from_row: i,
                                from_col: j,
                                to_row: to_row,
                                to_col: to_col
                            }

                            moves << move_info if basic_legal_move?(board_array, side, move_info)
                        end
                    end
                end
            end
        end

        def perpetual_check?(board_array, side, board_history, current_move)
            recent_boards = board_history.first(8)
            opponent_side = side == 'b' ? 'w' : 'b'
            
            # 現在の手が王手でなければ連続王手の千日手ではない
            return false unless in_check?(board_array, opponent_side)

            same_position_count = 1  # 現在の局面を1回とカウント
            check_sequence = true
            
            # 履歴をさかのぼって確認
            recent_boards.reverse_each do |board|
                parsed_data = board.parse_sfen

                # 自分の手番の時のみ王手のチェックを行う
                if parsed_data[:side] == side
                    return false unless in_check?(parsed_data[:board_array], opponent_side)
                end
            
                # 盤面が完全に一致しているかチェック
                same_position_count += 1 if parsed_data[:board_array] == board_array
                
                # 同一局面が4回出現し、かつすべての手が王手だった場合
                return true if same_position_count >= 4 && check_sequence
            end
            
            false
        end
            
        def repetition_draw?(board_array, board_history, current_move)
            # 盤面のハッシュを生成
            current_position = generate_position_hash(board_array)
            
            # 同一局面の出現回数をカウント
            position_count = board_history.count { |move| move[:position_hash] == current_position }
            
            # 4回目の同一局面で千日手
            position_count >= 3
        end
        
        def generate_position_hash(board_array)
            # 盤面を文字列化してハッシュ化
            board_array.map(&:join).join
        end

        def entering_king_rule?(board_array, side)
            king_pos = find_king(board_array, side)
            return false unless king_pos
        
            # 相手陣の範囲を定義
            enemy_territory = side == 'b' ? (0..2) : (6..8)
            
            # 王が相手陣に入っているか確認
            return false unless enemy_territory.include?(king_pos[0])
        
            # 点数計算（27点法の例）
            points = calculate_entering_king_points(board_array, side, enemy_territory)
            
            # 27点以上で入玉とみなす
            points >= 27
        end

        def calculate_entering_king_points(board_array, side, enemy_territory)
            points = 0
            
            board_array.each_with_index do |row, i|
                row.each_with_index do |piece, j|
                    next if piece.nil?
                    next if piece_owner(piece) != side
                    
                    # 相手陣内の駒のみカウント
                    next unless enemy_territory.include?(i)
                    
                    points += case piece.upcase
                    when 'P' then 1
                    when 'L', 'N', 'S' then 5
                    when 'G', 'B', 'R' then 10
                    else 0
                    end
                end
            end
            
            points
        end

        def simulate_move(board_array, move_info)
            new_board = Marshal.load(Marshal.dump(board_array))
            
            case move_info[:type]
            when :move
                new_board[move_info[:to_row]][move_info[:to_col]] = 
                    move_info[:promoted] ? 
                    "+#{new_board[move_info[:from_row]][move_info[:from_col]]}" : 
                    new_board[move_info[:from_row]][move_info[:from_col]]
                new_board[move_info[:from_row]][move_info[:from_col]] = nil
            when :drop
                piece = move_info[:piece]
                new_board[move_info[:to_row]][move_info[:to_col]] = piece
            end
            
            new_board
        end

        def basic_legal_move?(board_array, side, move_info)
            case move_info[:type]
            when :move then legal_move?(board_array, side, move_info)
            when :drop then legal_drop?(board_array, side, move_info)
            else false
            end
        end

        def find_king(board_array, side)
            king_symbol = side == 'b' ? 'K' : 'k'
            board_array.each_with_index do |row, i|
                row.each_with_index do |piece, j|
                    return [i, j] if piece == king_symbol
                end
            end
            nil
        end
    
        def piece_owner(piece)
            piece.upcase == piece ? 'b' : 'w'
        end
    
        # 二歩のチェック
        def validate_no_pawn_in_column?(board_array, col, side)
            column = board_array.map { |row| row[col] }
            column.any? do |cell|
                next false unless cell
                cell_type = cell.upcase
                cell_owner = cell.upcase == cell ? 'b' : 'w'
                cell_type == 'P' && cell_owner == side
            end
        end
        
        # 最奥段への打ち駒制限
        def drop_restriction_violation?(piece_type, to_row, side)
            case piece_type
            when 'P', 'L'
                (side == 'b' && to_row == 0) || (side == 'w' && to_row == 8)
            when 'N'
                (side == 'b' && to_row <= 1) || (side == 'w' && to_row >= 7)
            else
                false
            end
        end
    end
end