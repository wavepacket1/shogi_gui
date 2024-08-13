module Shogi 
    module Pieces
        attr_reader :name,:symbol,:color

        def initialize(name,symbol)
            @name = name
            @symbol = symbol
        end

        class FU 
            movement = [[0,1]]
        end

        class KE 
            movement = [[1,2],[-1,2]]
        end

        class OU
            movement = [
                [0,1],[1,0],[1,1],[1,-1],[-1,-1],[-1,0],[0,-1],[-1,1]
        ]
        end

        class KA 
            movement = []
            (1..8).each do |i|
                movement << [i,i]
                movement << [-i,i]
                movement << [i,-i]
                movement << [-i,-i]
            end
        end

        class KY 
            movement = []
            (1..8).each do |i|
                movement << [0,i]
            end
        end

        class GI
            movement = [[0,1],[1,1],[-1,1],[-1,1],[-1,-1]]
        end

        class KI 
            movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
        end

        class HI 
            movement = []
            (1..8 ).each do |i|
                movement << [0,i]
                movement << [0,-i]
                movement << [i,0]
                movement << [-i,0]
            end
        end

        class TO 
            movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
        end

        class NY
            movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
        end

        class NK 
            movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
        end

        class NG 
            movement = [[0,1],[1,1],[-1,1],[0,1],[1,0],[-1,0]]
        end

        class UM 
            movement = []
            (1..8).each do |i|
                movement << [i,i]
                movement << [-i,i]
                movement << [i,-i]
                movement << [-i,-i]
            end
            movement.concat([[0,1],[1,0],[0,-1],[-1,0],[1,1],[1,-1],[-1,1],[-1,-1]])
        end

        class RY 
            movement = []
            (1..8).each do |i|
                movement << [0,i]
                movement << [0,-i]
                movement << [i,0]
                movement << [-i,0]
            end
            movement.concat([1,1],[1,-1],[-1,1],[-1,-1])
        end
    end
end