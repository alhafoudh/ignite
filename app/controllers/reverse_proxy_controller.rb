class ReverseProxyController < ApplicationController
  def reconfigure
    ReverseProxyDeployer.new.configure

    render json: {
      success: true
    }
  end
end
