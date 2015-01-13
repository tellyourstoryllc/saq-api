# Create the one app-level index (# of shards can never be changed!)
namespace :elasticsearch do
  task configure: :environment do
    # Create the index if it doesn't yet exist
    begin
      ES.__elasticsearch__.client.indices.create(index: ES.index_name, body: {settings: ES.settings.to_hash})
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest
    end


    # Set/update all models' mappings
    models = [Story]

    models.each do |model|
      ES.es_req(:put, "/#{ES.index_name}/_mapping/#{model.document_type}", {}, model.mappings.to_hash)
    end
  end
end
