raise 'Missing VideoModerationRejectReason default record.' unless Rails.env.test? || VideoModerationRejectReason.find_default.present?
