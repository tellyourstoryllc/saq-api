class Comment < Message
  attr_accessor :collection_id, :collection_type


  def initialize(attributes = {})
    super
    self.type = 'comment'
  end

  def rank; end
  def self.redis_prefix; 'message' end

  # Disable some message functionality
  def forward_message_id=(*args); end
  def send_forward_meta_messages(*args); end
  def send_like_meta_messages(*args); end
  def send_export_meta_messages(*args); end


  def conversation
    return if collection_id.blank? || collection_type.blank?

    @conversation ||= case collection_type
                      when 'story' then Story.new(id: collection_id)
                      end
  end


  private

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless text.present? ||
      attachment_file.present? || attachment_url.present?
  end

  def conversation_id?
    errors.add(:base, "Both collection_id and collection_type are required.") if collection_id.blank? || collection_type.blank?
  end

  def write_attrs
    self.created_at = Time.current.to_i

    if @message_attachment && @message_attachment.attachment.present?
      self.attachment_url = @message_attachment.attachment.url
      self.attachment_content_type = @message_attachment.content_type
      self.attachment_preview_url = @message_attachment.preview_url
      self.attachment_preview_width = @message_attachment.preview_width
      self.attachment_preview_height = @message_attachment.preview_height
      self.message_attachment_id = @message_attachment.id
    end

    self.attrs.bulk_set(id: id, user_id: user_id, collection_id: collection_id, collection_type: collection_type,
                        text: text, mentioned_user_ids: @mentioned_user_ids,
                        message_attachment_id: message_attachment_id, attachment_url: attachment_url,
                        attachment_content_type: attachment_content_type,
                        attachment_preview_url: attachment_preview_url,
                        attachment_preview_width: attachment_preview_width,
                        attachment_preview_height: attachment_preview_height,
                        attachment_metadata: attachment_metadata, client_metadata: client_metadata, type: type,
                        created_at: created_at)
  end
end
