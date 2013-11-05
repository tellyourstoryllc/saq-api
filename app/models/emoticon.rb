class Emoticon < ActiveRecord::Base
  include Peanut::Model

  validates :name, :image_data, presence: true
  scope :active, -> { where(active: true) }

  VERSION = 7 


  def self.by_version(version)
    if version.to_i != VERSION
      active
    else
      []
    end
  end

  def self.reload
    r = /([^\/]+)\.[^\/]+$/
    Dir.glob('app/assets/images/emoticons/*.{png,gif}') do |filename|
      name = "(#{r.match(filename)[1]})"
      puts "Found emoticon #{name}"
      e = Emoticon.find_by_name(name) || Emoticon.new(name: name)
      e.image_data = Base64.encode64(File.read(filename))
      e.save!
    end
  end
end
