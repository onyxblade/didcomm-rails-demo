class SetupController < ApplicationController
  before_action :redirect_if_setup_done

  def new
  end

  def create
    admin = Admin.new(username: params[:username], password: params[:password], password_confirmation: params[:password_confirmation])

    unless admin.save
      flash.now[:alert] = admin.errors.full_messages.join(", ")
      return render :new, status: :unprocessable_entity
    end

    domain = ENV.fetch("DOMAIN", "localhost:3000")
    did = "did:web:#{domain.gsub(":", "%3A")}"

    identity = Identity.new(domain: domain, did: did)
    identity.generate_keys!

    unless identity.save
      admin.destroy
      flash.now[:alert] = identity.errors.full_messages.join(", ")
      return render :new, status: :unprocessable_entity
    end

    session[:admin_id] = admin.id
    redirect_to messages_path, notice: "Setup complete! Your DID is #{did}"
  end

  private

  def redirect_if_setup_done
    redirect_to root_path if Admin.any?
  end
end
