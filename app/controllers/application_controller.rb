class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?

  before_filter :authenticate_user!

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :name, :organization) }
    devise_parameter_sanitizer.for(:account_update) << :name
  end

  def anthenticate_vip!
    if not (current_user && current_user.vip)
      redirect_to :back, notice: 'You are not VIP'
      return
    end
  end
end
