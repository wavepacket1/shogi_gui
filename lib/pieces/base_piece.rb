module Shogi
    module Pieces
        class BasePiece
            # 駒の種類
            # 歩: P, 香: L, 桂: N, 銀: S, 金: G, 角: B, 飛: R, 王: K
            attr_reader :movement,:can_jump

            def initialize(movement,can_jump: false)
                @movement = movement
                @can_jump = can_jump
            end

            def movement_patterns
                @movement
            end
        end
    end
end