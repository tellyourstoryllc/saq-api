module Peanut::Search
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name Rails.configuration.app['app_name_short'].downcase

    # Convenience method to send arbitrary request to Elasticsearch
    def self.es_req(*args)
      __elasticsearch__.client.perform_request(*args)
    end
  end
end
