class Api::V1::App::DevicesController < ApplicationController
  def create
    device = current_user.devices.find_or_initialize_by(device_identifier: device_params[:device_identifier])
    device.assign_attributes(
      platform: device_params[:platform],
      app_version: device_params[:app_version],
      metadata: device_params[:metadata] || {},
      last_seen_at: Time.current
    )
    device.save!

    render json: {
      device: {
        id: device.id,
        device_identifier: device.device_identifier,
        platform: device.platform,
        app_version: device.app_version,
        last_seen_at: device.last_seen_at
      }
    }, status: :created
  end

  private

  def device_params
    params.require(:device).permit(:device_identifier, :platform, :app_version, metadata: {})
  end
end
