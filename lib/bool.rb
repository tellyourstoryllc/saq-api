class Bool
  def self.parse(value)
    case value
    when true, 'true', 1, '1' then true
    when false, 'false', 0, '0' then false
    else nil
    end
  end
end
