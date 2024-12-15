class Game < ApplicationRecord
    has_many :boards, dependent: :destroy

    validates :status, presence: true, inclusion: { in: ['active', 'completed'] }
end