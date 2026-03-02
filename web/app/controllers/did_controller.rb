class DidController < ApplicationController
  def show
    identity = Identity.instance
    render json: identity.did_document
  rescue Identity::NotConfiguredError
    render json: { error: "Not configured" }, status: :not_found
  end
end
