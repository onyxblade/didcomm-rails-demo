class SessionsController < ApplicationController
  before_action :require_setup

  def new
  end

  def create
    admin = Admin.find_by(username: params[:username])

    if admin&.authenticate(params[:password])
      session[:admin_id] = admin.id
      redirect_to messages_path, notice: "Logged in."
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin_id)
    redirect_to root_path, notice: "Logged out."
  end
end
