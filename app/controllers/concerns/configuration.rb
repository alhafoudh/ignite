module Configuration
  extend ActiveSupport::Concern

  included do
    before_action :configure
  end

  private

  def configure
    Current.config = Config.instance
  end
end