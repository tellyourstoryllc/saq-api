require 'typhoeus'
require 'typhoeus/adapters/faraday'

client = Elasticsearch::Client.new(
  url: Rails.configuration.app['elasticsearch']['url'],
  log: true
)

Elasticsearch::Model.client = client
