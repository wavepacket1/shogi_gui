class Player 
    attr_accessor :name, :turn,:captured_pieces
    def initialize(name,turn)
        @name = name
        #先手(:sente)か後手(:gote)を示す
        @turn = turn
        @captured_pieces = []
    end

    def get_move 
        # ユーザーからの入力を取得するロジック
        puts "#{@name}のターンです。移動元と移動先を入力してください(例: 7776P)"
        input = gets.chomp
    end
end