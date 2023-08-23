class Deployment < ApplicationRecord
  belongs_to :app

  has_one_attached :source
end
