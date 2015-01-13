# Generic model used to easily access Elasticsearch
class ES
  include Peanut::Search

  settings index: {number_of_shards: 3, number_of_replicas: 0} do
  end
end
