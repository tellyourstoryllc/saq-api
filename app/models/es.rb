# Generic model used to easily access Elasticsearch
class ES
  include Peanut::Search

  settings index: {number_of_shards: 3, number_of_replicas: 0} do
  end


  def self.index(object)
    return

    if Settings.enabled?(:queue)
      ElasticsearchWorker.perform_async(:index, object.class.to_s, object.id)
    else
      index!(object)
    end
  end

  def self.index!(object)
    return

    object.__elasticsearch__.index_document
  end

  def self.update_attributes(object, update_attrs)
    return

    if Settings.enabled?(:queue)
      ElasticsearchWorker.perform_async(:update_attributes, object.class.to_s, object.id, update_attrs)
    else
      update_attributes!(object, update_attrs)
    end
  end

  def self.update_attributes!(object, update_attrs)
    return

    if object.indexed_in_es?
      object.__elasticsearch__.update_document_attributes(update_attrs)
    else
      index!(object)
    end
  end

  def self.delete(object)
    return

    if Settings.enabled?(:queue)
      ElasticsearchWorker.perform_async(:delete, object.class.to_s, object.id)
    else
      delete!(object)
    end
  end

  def self.delete!(object)
    return

    object.__elasticsearch__.delete_document
  end
end
