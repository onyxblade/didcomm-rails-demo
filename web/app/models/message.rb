class Message < ApplicationRecord
  validates :direction, inclusion: { in: %w[sent received] }
  validates :status, inclusion: { in: %w[draft sent delivered failed] }

  scope :sent, -> { where(direction: "sent") }
  scope :received, -> { where(direction: "received") }

  def body_parsed
    JSON.parse(body) rescue body
  end
end
