module Peanut::Search
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name Rails.configuration.app['app_name_short'].downcase

    # Convenience method to send arbitrary request to Elasticsearch
    def self.es_req(*args)
      __elasticsearch__.client.perform_request(*args)
    end

    def indexed_in_es?
      return false unless self.class.respond_to?(:es_req)

      res = self.class.es_req(:head, "#{self.class.index_name}/#{self.class.document_type}/#{id}")
      res.status == 200

    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      false
    end
  end
end
