class ApplicationController < ActionController::Base
  before_action :set_default_url_options

  private

  def set_default_url_options
    Rails.application.base_url(request)
      .then do |uri|
      base_url = uri.to_s

      ActionMailer::Base.default_url_options[:host] = base_url
      Rails.application.default_url_options[:host] = base_url
    end
  end
end
