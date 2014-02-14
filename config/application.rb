require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module KrazyChat
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true
    I18n.config.enforce_available_locales = true

    config.active_record.schema_format = :sql

    # Disable Asset Pipeline
    config.assets.enabled = false

    config.generators do |g|
      g.test_framework :mini_test, spec: true, fixture: false
      g.helper false
      g.assets false
      g.view_specs false
    end

    # Change upload temp dir from /tmp to /mnt/rails,
    # so it uses the larger instance storage
    tmp_dir = '/mnt/rails'
    ENV['TMPDIR'] = tmp_dir if File.directory?(tmp_dir)

    config.autoload_paths += %W(#{config.root}/lib)
  end
end
