module Peanut
  class UnauthorizedError < StandardError
  end

  module Redis
    class RecordNotFound < StandardError
    end
  end
end
