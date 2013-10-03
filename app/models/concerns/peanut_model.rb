module PeanutModel
  extend ActiveSupport::Concern

  def object_type
    self.class.name.underscore
  end
end
