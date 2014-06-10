class Story < Message
  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end




  end
end
