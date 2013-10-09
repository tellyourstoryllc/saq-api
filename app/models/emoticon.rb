class Emoticon < ActiveRecord::Base
  include Peanut::Model

  validates :name, :image_data, presence: true
  scope :active, -> { where(active: true) }

  VERSION = 1


  def self.by_version(version)
    if version.to_i != VERSION
      active
    else
      []
    end
  end
end
