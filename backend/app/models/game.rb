class Game < ApplicationRecord
    has_one :board, dependent: :destroy

    validates :name, presence: true
    validates :status, presence: true, inclusion: { in: ['waiting', 'active', 'finished'] }
    validates :active_player, presence: true, inclusion: { in: ['b', 'w'] }
end