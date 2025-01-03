class Validator
    class << self
        # 合法手かどうかを判定する
        def legal?(parsed_data, move_info)
            board_array = parsed_data[:board_array]
            side = parsed_data[:side]

            return false unless basic_legal_move?(board_array, side, move_info)
            
            # 王手放置のチェック
            simulated_board = simulate_move(board_array, move_info)
            return false if in_check?(simulated_board, side)

            # 打ち歩詰めのチェック
            return false if pawn_drop_mate?(board_array, side, move_info)

            # 連続王手の判定
            return false if perpetual_check?(simulated_board, side, move_history, move_info)
    
            # 千日手の判定
            return false if repetition_draw?(simulated_board, move_history, move_info)
            
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

        private 

        def perpetual_check?(board_array, side, move_history, current_move)
            # 直近の4手をチェック（連続王手は3手で判定可能）
            recent_moves = move_history.last(4)
            return false if recent_moves.length < 4
      
            # 現在の手が王手かどうかチェック
            opponent_side = side == 'b' ? 'w' : 'b'
            return false unless in_check?(board_array, opponent_side)
      
            # 直近の自分の手がすべて王手だったかチェック
            consecutive_checks = 1
            recent_moves.reverse.each_with_index do |move, i|
              next if i.odd? # 相手の手はスキップ
              
              if move[:check]
                consecutive_checks += 1
              else
                break
              end
            end
      
            consecutive_checks >= 4
          
            
            def repetition_draw?(board_array, move_history, current_move)
                # 盤面のハッシュを生成
                current_position = generate_position_hash(board_array)
                
                # 同一局面の出現回数をカウント
                position_count = move_history.count { |move| move[:position_hash] == current_position }
                
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
            new_board = board_array.deep_dup
            
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

        # 盤面の状態を保存するための構造体
    class Position
        attr_reader :board_array, :hands, :side_to_move
  
        def initialize(board_array, hands, side_to_move)
          @board_array = board_array
          @hands = hands
          @side_to_move = side_to_move
        end
  
        def ==(other)
          board_array == other.board_array &&
          hands == other.hands &&
          side_to_move == other.side_to_move
        end
  
        def hash
          [board_array, hands, side_to_move].hash
        end
      end

      def record_position(board_array, hands, side, move_history)
        current_position = Position.new(
          Marshal.load(Marshal.dump(board_array)),
          Marshal.load(Marshal.dump(hands)),
          side
        )
  
        move_history << {
          position: current_position,
          check: in_check?(board_array, side == 'b' ? 'w' : 'b')
        }
      end
    end
end

    
