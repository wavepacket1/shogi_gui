class Game < ApplicationRecord
  has_one :board, dependent: :destroy
  has_many :board_histories, dependent: :destroy
  belongs_to :black_player, class_name: 'User', optional: true
  belongs_to :white_player, class_name: 'User', optional: true
  
  validates :status, presence: true, inclusion: { in: ['active', 'finished', 'pause'] }
  validates :mode, presence: true, inclusion: { in: ['play', 'edit', 'study'] }

  def mode=(value)
    if ['play', 'edit', 'study'].include?(value)
      write_attribute(:mode, value)
    else
      raise ArgumentError, "Invalid mode: #{value}"
    end
  end

  def nyugyoku_declaration(board)
    ## 入玉宣言の処理を実装する
    Validator.nyugyoku_27?(board.sfen)
  end
end