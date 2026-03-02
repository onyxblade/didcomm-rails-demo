class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  private

  def current_admin
    @current_admin ||= Admin.find_by(id: session[:admin_id]) if session[:admin_id]
  end
  helper_method :current_admin

  def require_login
    unless current_admin
      redirect_to login_path, alert: "Please log in."
    end
  end

  def require_setup
    if Admin.none?
      redirect_to setup_path, alert: "Please complete setup first."
    end
  end
end
