module Peanut::RedisModel
  extend ActiveSupport::Concern

  def initialize(attributes = {})
    if id.present?
      attrs.all.each do |k,v|
        v = nil if v.blank?
        send("#{k}=", v)
      end
    end
  end

  def to_int(*attrs)
    attrs.each do |attr|
      value = send(attr)
      send("#{attr}=", value.present? ? value.to_i : nil)
    end
  end
end
