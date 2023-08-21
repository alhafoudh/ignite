class DeploymentController < ApplicationController
  include ActionController::Live

  skip_before_action :verify_authenticity_token

  def create
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate

    sse = SSE.new(response.stream, retry: 300, event: "open")
    # sse = nil

    app_id = params[:id]
    app = App.find(app_id)

    send_event(sse, :image_build, :start)
    image = AppBuilder
      .new(params[:file])
      .run do |log|
      send_event(sse, :log, nil, log)
    end
    send_event(sse, :image_build, :end, image.id)

    send_event(sse, :container_deploy, :start)
    app_container = AppDeployer.new(app, image).redeploy
    send_event(sse, :container_deploy, :end, app_container&.id)

    reverse_proxy_deployer = ReverseProxyDeployer.new
    reverse_proxy_deployer.undeploy

    send_event(sse, :reverse_proxy_depoy, :start)
    reverse_proxy = reverse_proxy_deployer.ensure
    send_event(sse, :reverse_proxy_depoy, :end, reverse_proxy.id)

    send_event(sse, :reverse_proxy_configure, :start)
    reverse_proxy_deployer.wait_ready
    reverse_proxy_deployer.configure
    send_event(sse, :reverse_proxy_configure, :end)

    sse.write({}, event: "close")
    # render json: {}
  rescue ActionController::Live::ClientDisconnected
    sse.close
  ensure
    sse.close
  end

  private

  def send_event(sse, event, phase = nil, payload = nil)
    Rails.logger.info({ event:, phase:, payload: })
    sse.write({
      type: event,
      phase:,
      payload:,
    }.compact,
      event: "message")
  end
end
