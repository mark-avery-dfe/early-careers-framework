# frozen_string_literal: true

class ParticipantProfile::ECT < ParticipantProfile::ECF
  COURSE_IDENTIFIERS = %w[ecf-induction].freeze

  belongs_to :mentor_profile, class_name: "Mentor", optional: true
  has_one :mentor, through: :mentor_profile, source: :user

  scope :awaiting_induction_registration, lambda {
    where(induction_start_date: nil).joins(:ecf_participant_eligibility).merge(ECFParticipantEligibility.waiting_for_induction)
  }

  def self.archivable(for_cohort_start_year:, restrict_to_participant_ids: [])
    latest_induction_start_date = Date.new(for_cohort_start_year, 9, 1)

    super(for_cohort_start_year:, restrict_to_participant_ids:)
      .where(induction_completion_date: nil)
      .where("induction_start_date IS NULL OR induction_start_date < ?", latest_induction_start_date)
  end

  def ect?
    true
  end

  def participant_type
    :ect
  end

  def role
    "Early career teacher"
  end

  def self.eligible_to_change_cohort_and_continue_training(in_cohort_start_year:, restrict_to_participant_ids:)
    super(in_cohort_start_year:, restrict_to_participant_ids:).where(induction_completion_date: nil)
  end
end
