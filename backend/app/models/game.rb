class Game < ApplicationRecord
  has_one :board, dependent: :destroy
  validates :status, presence: true, inclusion: { in: ['active', 'finished', 'pause'] }

  def nyugyoku_declaration(board)
    ## 入玉宣言の処理を実装する
    Validator.nyugyoku_27?(board.sfen)
  end
end