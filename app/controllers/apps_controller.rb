class AppsController < ApplicationController
  def index
    @apps = App.all.order('last_deployed_at DESC NULLS LAST')
  end
end
