class PublicController < ApplicationController
  def index
    @messages = Message.visible.order(created_at: :desc)
  end
end
