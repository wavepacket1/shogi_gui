class Piece < ApplicationRecord
  VALID_PIECE_TYPES = %w[K G S N L R B P k g s n l r b p]

  belongs_to :board

  validates :position_x, presence: true, inclusion: { in: 0..8 }
  validates :position_y, presence: true, inclusion: { in: 0..8 }
  validates :piece_type, presence: true, inclusion: { in: VALID_PIECE_TYPES } # 駒の種類
  validates :owner, presence: true, inclusion: { in: ['b', 'w'] }
end
