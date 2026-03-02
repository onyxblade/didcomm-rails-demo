class Message < ApplicationRecord
  validates :direction, inclusion: { in: %w[sent received] }
  validates :visibility, inclusion: { in: %w[private public] }
  validates :status, inclusion: { in: %w[draft sent delivered failed] }

  scope :sent, -> { where(direction: "sent") }
  scope :received, -> { where(direction: "received") }
  scope :visible, -> { where(visibility: "public") }

  def body_parsed
    JSON.parse(body) rescue body
  end
end
