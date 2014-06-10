class Story < Message
  def initialize(attributes = {})
    super
    self.type = 'story'
  end
end
