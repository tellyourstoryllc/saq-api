require 'hook_api_client'
HookApiClient.logger = Rails.logger
HookApiClient.default_params(passcode: Rails.configuration.app['hook']['passcode'])

HOOK_CLIENT = HookClient.new
