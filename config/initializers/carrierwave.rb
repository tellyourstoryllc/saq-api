aws_config = Rails.configuration.app['aws']
carrierwave_config = Rails.configuration.app['carrierwave']

CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',                           # required
    :aws_access_key_id      => aws_config['access_key_id'],     # required
    :aws_secret_access_key  => aws_config['secret_access_key'], # required
    :region                 => 'us-west-2',                     # optional, defaults to 'us-east-1'
    #:host                   => 's3.example.com',                # optional, defaults to nil
    #:endpoint               => 'https://s3.example.com:8080'    # optional, defaults to nil
    :endpoint               => 'https://s3.amazonaws.com'       # optional, defaults to nil
  }
  config.fog_directory  = aws_config['bucket_name']               # required
  config.fog_public     = true                                    # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
  config.asset_host     = carrierwave_config['cdn_url'] || 'https://s3.amazonaws.com/' + aws_config['bucket_name']
end
