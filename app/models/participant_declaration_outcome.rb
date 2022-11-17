# frozen_string_literal: true

class ParticipantDeclarationOutcome < ApplicationRecord
  VALID_STATES = %i[passed failed voided].freeze
  private_constant :VALID_STATES

  belongs_to :participant_declaration
  enum state: VALID_STATES.index_with(&:to_s)

  validates :state, presence: true
  validates :completion_date, presence: true
  validate :completion_is_not_in_future, if: :completion_date

private

  def completion_is_not_in_future
    return if completion_date <= Time.zone.today

    errors.add(:completion_date, "Cannot be in the future")
  end
end
