module Peanut::Model
  extend ActiveSupport::Concern

  def object_type
    self.class.name.underscore
  end

  def to_int(*attrs)
    attrs.each do |attr|
      value = send(attr)
      send("#{attr}=", value.present? ? value.to_i : nil)
    end
  end
end
