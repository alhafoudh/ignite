class DeploymentsController < ApplicationController
  include ActionController::Live

  skip_before_action :verify_authenticity_token
  before_action :set_app

  def create
    @deployment = @app.deployments.create!
    @deployment.source.attach(params[:file])

    render json: {
      id: @deployment.id,
    }
  end

  def start
    @deployment = @app.deployments.find(params[:id])

    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate

    sse = SSE.new(response.stream, retry: 300, event: "open")

    send_event(sse, :network_deploy, :start)
    network = NetworkDeployer.new.ensure
    send_event(sse, :network_deploy, :end, network.id)

    send_event(sse, :image_build, :start)

    image = nil
    @deployment.source.open do |file|
      image = AppBuilder
        .new(file)
        .run do |chunk|
        send_event(sse, :log, nil, chunk)
      end
    end
    send_event(sse, :image_build, :end, image.id)

    @app.update!(image: image.id)

    send_event(sse, :container_deploy, :start)
    app_container = @app.build_deployer.redeploy(@app.image)
    send_event(sse, :container_deploy, :end, app_container.id)

    reverse_proxy_deployer = ReverseProxyDeployer.new

    send_event(sse, :reverse_proxy_depoy, :start)
    reverse_proxy = reverse_proxy_deployer.ensure
    send_event(sse, :reverse_proxy_depoy, :end, reverse_proxy.id)

    send_event(sse, :reverse_proxy_configure, :start)
    reverse_proxy_deployer.wait_ready
    reverse_proxy_deployer.configure
    send_event(sse, :reverse_proxy_configure, :end)

    send_event(sse, :app_deployed, nil, {
      url: @app.url
    })

    @app.update!(last_deployed_at: Time.zone.now)

  rescue => ex
    send_event(sse, :error, nil, {
      message: ex.message,
    })
    raise ex
  ensure
    close_event(sse)
    sse.close
  end

  private

  def set_app
    app_id = params[:app_id].parameterize
    @app = App.find_or_create_by!(name: app_id)
  end

  def send_event(sse, event, phase = nil, payload = nil)
    Rails.logger.tagged(:sse).debug({ event:, phase:, payload: })
    sse.write({
      type: event,
      phase:,
      payload:,
    }.compact,
      event: "message")
  end

  def close_event(sse)
    Rails.logger.tagged(:sse).info({ event: :close })
    sse.write({
      type: "close",
    }, event: "message")
  end
end
