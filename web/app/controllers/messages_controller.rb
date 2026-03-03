class MessagesController < ApplicationController
  before_action :require_login

  def index
    @messages = Message.order(created_at: :desc)
  end

  def show
    @message = Message.find(params[:id])
  end

  def new
  end

  def create
    to_did = params[:to_did].strip
    body_content = params[:body].strip
    anonymous = params[:anonymous] == "1"

    body_hash = begin
      JSON.parse(body_content)
    rescue JSON::ParserError
      { "content" => body_content }
    end

    message = Message.create!(
      didcomm_id: SecureRandom.uuid,
      direction: "sent",
      from_did: anonymous ? nil : Identity.did,
      to_did: to_did,
      message_type: "https://didcomm.org/basicmessage/2.0/message",
      body: body_hash.to_json,
      status: "draft"
    )

    sender = MessageSender.new(message, anonymous: anonymous)
    if sender.deliver
      redirect_to message_path(message), notice: "Message #{message.status}."
    else
      redirect_to message_path(message), alert: "Failed to send: #{message.error_message}"
    end
  end

  def resend
    message = Message.find(params[:id])

    sender = MessageSender.new(message, anonymous: message.from_did.nil?)
    if sender.deliver
      redirect_to message_path(message), notice: "Message #{message.status}."
    else
      redirect_to message_path(message), alert: "Failed to send: #{message.error_message}"
    end
  end
end
