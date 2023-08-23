require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Oj.optimize_rails

module Ignite
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.generators do |g|
      g.assets false
      g.helper false
      g.test_framework nil
      g.system_tests = nil
      g.jbuilder false
      g.factory_bot false
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework nil
      g.factory_bot false

      # g.fixture_replacement :factory_bot, dir: 'spec/factories'

      g.controller_specs false
      g.request_specs false
      g.view_specs false
      g.helper_specs false
      g.routing_specs false
    end

    config.log_formatter = ::Logger::Formatter.new
    config.logger = begin
      logger = ActiveSupport::Logger.new($stdout)
      logger.formatter = config.log_formatter
      ActiveSupport::TaggedLogging.new(logger)
    end

    config.time_zone = 'Bratislava'
    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en]

    config.assets.css_compressor = nil # solves tailwindcss purgecss issue

    config.middleware.use Rack::Deflater # enabled gzip

    config.hosts = nil # disable host checking

    config.i18n.raise_on_missing_translations = true

    def base_url(request)
      URI.parse(request.url)
        .tap do |uri|
        uri.query = uri.fragment = nil
        uri.path = ''
      end
    end
  end
end
