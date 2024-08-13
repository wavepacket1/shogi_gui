module Shogi 
    class Pieces
        attr_reader :name,:symbol,:color

        def initialize(name,symbol)
            # @name = name
            # @symbol = symbol
        end

        ##次の位置まで駒が動けるかをvalidationする
        def self.validate_movement(board,present_position,next_position,turn,movement)
            movement.each do |move|
                if ((turn)*move[1] + present_position[0] != next_position[0]) && ((turn)*move[0] + present_position[1] != next_position[1]) 
                    next
                end
                ## 次の位置の間に駒がないかをvalidationする
                pieces_between_flag= true
                (0..move[1]).each do |move_x_between|
                    (0..move[0]).each do |move_y_between|
                        if(board[(turn)*move_x_between+present_position[0]][(turn)*move_y_between+present_position[1]])
                            flag = false
                        end
                    end
                end
                return pieces_between_flag if pieces_between_flag
            end
            false
        end
        class FU
            @movement = [[0,1]]
            def self.fu_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(board,present_position,next_position,turn,@movement)
            end
        end
        class KE 
            @movement = [[1,2],[-1,2]]
            def self.ke_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class OU
            @movement = [
                [0,1],[1,0],[1,1],[1,-1],[-1,-1],[-1,0],[0,-1],[-1,1]
        ]
            def self.ou_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class KA 
            @movement = []
            (1..8).each do |i|
                @movement << [i,i]
                @movement << [-i,i]
                @movement << [i,-i]
                @movement << [-i,-i]
            end
            def self.ka_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class KY 
            @movement = []
            (1..8).each do |i|
                @movement << [0,i]
            end
            def self.ka_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class GI
            @movement = [[0,1],[1,1],[-1,1],[-1,1],[-1,-1]]
            def self.gi_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class KI 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.ki_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class HI 
            @movement = []
            (1..8 ).each do |i|
                @movement << [0,i]
                @movement << [0,-i]
                @movement << [i,0]
                @movement << [-i,0]
            end
            def self.hi_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class TO 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.to_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class NY
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.ny_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class NK 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.nk_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end

        class NG 
            @movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
            def self.ng_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
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
            def self.um_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
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
            def self.ry_validation(board,present_position,next_position,turn)
                Shogi::Pieces::validate_movement(present_position,next_position,turn,@movement)
            end
        end
    end
end