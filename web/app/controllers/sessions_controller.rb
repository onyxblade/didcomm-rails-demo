class SessionsController < ApplicationController
  def new
  end

  def create
    if params[:password] == ENV["ADMIN_PASSWORD"]
      session[:password] = ENV["ADMIN_PASSWORD"]
      redirect_to messages_path, notice: "Logged in."
    else
      flash.now[:alert] = "Invalid password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out."
  end
end
