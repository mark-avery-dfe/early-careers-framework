# frozen_string_literal: true

class AppropriateBody < ApplicationRecord
  has_paper_trail

  enum body_type: {
    local_authority: "local_authority",
    teaching_school_hub: "teaching_school_hub",
    national: "national",
  }

  has_many :appropriate_body_profiles, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :body_type }

  default_scope { order(:name) }

  scope :name_order, -> { order("UPPER(name)") }
  scope :local_authorities, -> { where(body_type: :local_authority) }
  scope :teaching_school_hubs, -> { where(body_type: :teaching_school_hub) }
  scope :nationals, -> { where(body_type: :national) }

  after_save :update_analytics

private

  def update_analytics
    Analytics::UpsertECFAppropriateBodyJob.perform_later(appropriate_body: self) if saved_changes?
  end
end
