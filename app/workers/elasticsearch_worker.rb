class ElasticsearchWorker < BaseWorker
  def self.category; :elasticsearch end
  def self.metric; :index end

  def perform(operation, class_name, id, update_attrs = {})
    perform_with_tracking(operation, class_name, id, update_attrs) do
      model = class_name.constantize
      object = model.respond_to?(:find) ? model.find(id) : model.new(id: id)

      case operation
      when 'index', 'delete'
        ES.send(operation + '!', object)
      when 'update_attributes'
        ES.update_attributes!(object, update_attrs)
      end

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
