class PublicController < ApplicationController
  def index
    @identity = Identity.first
    @messages = Message.visible.order(created_at: :desc)
  end
end
