module Peanut::Model
  extend ActiveSupport::Concern

  def object_type
    self.class.name.underscore
  end

  def to_int(*attrs)
    attrs.each do |attr|
      send("#{attr}=", send(attr).to_i)
    end
  end
end
