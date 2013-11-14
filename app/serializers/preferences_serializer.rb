class PreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :client_web, :client_ios, :server_mention_email, :server_mention_ios,
    :server_one_to_one_email, :server_one_to_one_ios, :created_at

  def server_mention_email
    !object.server_mention_email.nil? ? object.server_mention_email : Preferences::DEFAULTS[:server_mention_email]
  end

  def server_mention_ios
    !object.server_mention_ios.nil? ? object.server_mention_ios : Preferences::DEFAULTS[:server_mention_ios]
  end

  def server_one_to_one_email
    !object.server_one_to_one_email.nil? ? object.server_one_to_one_email : Preferences::DEFAULTS[:server_one_to_one_email]
  end

  def server_one_to_one_ios
    !object.server_one_to_one_ios.nil? ? object.server_one_to_one_ios : Preferences::DEFAULTS[:server_one_to_one_ios]
  end
end
