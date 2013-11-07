module Peanut::RedisModel
  extend ActiveSupport::Concern
  include Peanut::Model
  include ActiveModel::Model
  include ActiveModel::SerializerSupport

  attr_accessor :fetched


  included do
    def self.pipelined_find(ids)
      attrs = redis.pipelined do
        ids.map{ |id| redis.hgetall("#{redis_prefix}:#{id}:attrs") }
      end

      attrs.map{ |attrs| new(attrs.merge(fetched: true)) }
    end
  end

  def initialize(attributes = {})
    # Set all the instance variables
    super

    # If the attributes have already been fetched (e.g. pipelined fetches for performance),
    # then just set the attributes
    # Else if an id is specified, fetch the attributes from Redis
    attributes = attributes.with_indifferent_access
    fetched_attrs = if attributes.delete(:fetched)
                      attributes
                    elsif id.present?
                      attrs.all
                    end

    if fetched_attrs
      fetched_attrs.each do |k,v|
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
