module Shogi 
    class Pieces
        # attr_reader :name,:symbol,:color

        def initialize(name,symbol)
            # @name = name
            # @symbol = symbol
        end

        ##次の位置まで駒が動けるかをvalidationする
        def self.validate_movement(board,present_position,next_position,move_direction,movement)
            movement.each do |move|
                if ((move_direction)*move[1] + present_position[0] == next_position[0]) && ((move_direction)*move[0] + present_position[1] == next_position[1]) 
                    #桂馬の時
                    return true if (move[0] == 1 && move[1] == 2) || (move[0] == -1 && move[1] == 2)
                    max_constant =  if move[0]!= 0
                                        move[0].abs 
                                    elsif move[1]!= 0
                                        move[1].abs
                                    else
                                        0
                                    end
                    return true if max_constant == 0
                    unit_move = move.map{|i| i/max_constant}
                    return true if (max_constant.abs == 1)
                    (1..max_constant-1).each do |constant|
                        if(board[(move_direction)*constant*unit_move[1]+present_position[0]][(move_direction)*constant*unit_move[0]+present_position[1]])
                            puts "エラー！動かそうとしている位置の間に駒があります"
                            return false
                        end
                    end
                    return true
                end
            end
            puts "エラー!駒が動ける範囲外です"
            false
        end

        def self.can_move_validation(board,next_position,move_direction,movement)
            movement.each do |move|
                return true if((0<= next_position[0]+move_direction*move[1] && next_position[0]+move_direction*move[1]<=8) && (0<= next_position[1]+move_direction*move[0] && next_position[1]+move_direction*move[0]))
            end
            false
        end

        class P
            @movement = [[0,1]]
            def self.p_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.p_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end
        class N
            @movement = [[1,2],[-1,2]]
            def self.n_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.n_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class K
            @movement = [
                [0,1],[1,0],[1,1],[1,-1],[-1,-1],[-1,0],[0,-1],[-1,1]
        ]
            def self.k_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.k_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class B 
            @movement = []
            (1..8).each do |i|
                @movement << [i,i]
                @movement << [-i,i]
                @movement << [i,-i]
                @movement << [-i,-i]
            end
            def self.b_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.b_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class L
            @movement = []
            (1..8).each do |i|
                @movement << [0,i]
            end
            def self.l_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.l_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class S
            @movement = [[0,1],[1,1],[-1,1],[-1,1],[-1,-1]]
            def self.s_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.s_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class G
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.g_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.g_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class R
            @movement = []
            (1..8 ).each do |i|
                @movement << [0,i]
                @movement << [0,-i]
                @movement << [i,0]
                @movement << [-i,0]
            end
            def self.r_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.r_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class TO 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.to_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.to_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class NY
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.ny_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.ny_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class NK 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.nk_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.nk_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class NG 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.ng_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.ng_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class UM 
            @movement = []
            (1..8).each do |i|
                @movement << [i,i]
                @movement << [-i,i]
                @movement << [i,-i]
                @movement << [-i,-i]
            end
            @movement.concat([[0,1],[1,0],[0,-1],[-1,0],[1,1],[1,-1],[-1,1],[-1,-1]])
            def self.um_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.um_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end

        class RY 
            @movement = []
            (1..8).each do |i|
                @movement << [0,i]
                @movement << [0,-i]
                @movement << [i,0]
                @movement << [-i,0]
            end
            @movement.concat([1,1],[1,-1],[-1,1],[-1,-1])
            def self.ry_validation(board,present_position,next_position,move_direction)
                Shogi::Pieces::validate_movement(board,present_position,next_position,move_direction,@movement)
            end

            def self.ry_can_move_validation(board,next_position,move_direction)
                Shogi::Pieces::can_move_validation(board,next_position,move_direction,@movement)
            end
        end
    end
end