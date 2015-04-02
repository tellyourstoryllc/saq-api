module Peanut
  class MissingTimestampError < StandardError
  end

  class InvalidSignatureError < StandardError
  end

  class UnauthorizedError < StandardError
  end

  module Redis
    class RecordNotFound < StandardError
    end
  end

  class YouTubeAPIError < StandardError
  end
end
