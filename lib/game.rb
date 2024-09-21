require_relative "board"
require_relative "player"

#フロント側の処理
class Game
    attr_accessor :board,:current_player
    def initialize
        @board = Shogi::Board.new
        @players = [ Player.new("先手",:sente),Player.new("後手",:gote) ]
        @current_player_index = 0
    end

    def start
        loop do 
            display_board
            current_player = @players[@current_player_index]
            move_protocol = current_player.get_move
            begin 
                @board.move(move_protocol)
            rescue => e 
                puts "エラー: #{e.message}"
                next
            end
            # break if @board.checkmate?(current_player.opponent)
            switch_turn
        end
        puts "#{players[@current_player_index].name}の勝利です！"
    end

    private 

    def display_board
        @board.display
    end

    def reset_board
        @board.reset
    end

    def switch_turn
        @current_player_index = 1 - @current_player_index
    end
end