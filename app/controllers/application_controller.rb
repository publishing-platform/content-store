class ApplicationController < ActionController::API
  include PublishingPlatform::SSO::ControllerMethods

  before_action :authenticate_user!
end
