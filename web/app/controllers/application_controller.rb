class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :ensure_identity

  private

  def logged_in?
    session[:password].present? && session[:password] == ENV["ADMIN_PASSWORD"]
  end
  helper_method :logged_in?

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in."
    end
  end

  def ensure_identity
    return if Identity.any?

    domain = ENV.fetch("DOMAIN", "localhost:3000")
    did = "did:web:#{domain.gsub(":", "%3A")}"

    identity = Identity.new(domain: domain, did: did)
    identity.generate_keys!
    identity.save!
  end
end
