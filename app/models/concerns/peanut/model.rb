module Peanut::Model
  extend ActiveSupport::Concern

  included do
    def self.to_bool(value)
      case value
      when true, 'true', 1, '1' then true
      when false, 'false', 0, '0' then false
      else nil
      end
    end
  end

  def object_type
    self.class.name.underscore
  end
end
