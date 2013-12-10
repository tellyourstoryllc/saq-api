class Emoticon < ActiveRecord::Base
  include Peanut::Model

  before_validation :set_sha1
  validates :name, :image, :local_file_path, :sha1, presence: true
  scope :active, -> { where(active: true) }

  mount_uploader :image, EmoticonUploader


  def self.reload
    Emoticon.update_all(active: false)

    r = /([^\/]+)\.[^\/]+$/
    Dir.glob('app/assets/images/emoticons/*.{png,gif}') do |file_path|
      name = ":#{r.match(file_path)[1]}:"
      puts "Found emoticon #{name}"
      e = Emoticon.find_by_name(name) || Emoticon.new(name: name)
      e.image = File.open(file_path)
      e.local_file_path = file_path
      e.active = true
      e.save!
    end
  end


  private

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(File.read(local_file_path))
  end
end
