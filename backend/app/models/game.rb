class Game < ApplicationRecord
  has_one :board, dependent: :destroy
  validates :status, presence: true, inclusion: { in: ['active', 'completed'] }
end