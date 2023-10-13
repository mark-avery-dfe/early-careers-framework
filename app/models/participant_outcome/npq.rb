# frozen_string_literal: true

class ParticipantOutcome::NPQ < ApplicationRecord
  has_paper_trail

  self.table_name = "participant_outcomes"

  VALID_STATES = %i[passed failed voided].freeze
  PERMITTED_STATES = %i[passed failed].freeze
  private_constant :VALID_STATES

  belongs_to :participant_declaration, class_name: "ParticipantDeclaration::NPQ"
  has_many :participant_outcome_api_requests, foreign_key: :participant_outcome_id

  enum state: VALID_STATES.index_with(&:to_s)

  validates :state, presence: true
  validates :completion_date, presence: true, future_date: true

  after_commit :push_outcome_to_big_query

  class << self
    def latest
      order(created_at: :desc).first
    end

    def to_send_to_qualified_teachers_api
      eligible_outcomes = not_sent_to_qualified_teachers_api
        .where(id: latest_per_declarations.map(&:id))

      eligible_outcomes.passed
        .or(
          eligible_outcomes
            .not_passed
            .where(participant_declaration_id: declarations_where_outcome_passed_and_sent),
        )
    end

    def latest_per_declarations
      select("DISTINCT ON(participant_declaration_id) *")
        .order(:participant_declaration_id, created_at: :desc)
    end

    def declarations_where_outcome_passed_and_sent
      latest_per_declarations
        .passed
        .sent_to_qualified_teachers_api
        .map(&:participant_declaration_id)
    end

    def sent_to_qualified_teachers_api
      where.not(sent_to_qualified_teachers_api_at: nil)
    end

    def not_sent_to_qualified_teachers_api
      where(sent_to_qualified_teachers_api_at: nil)
    end

    def passed
      where(state: :passed)
    end

    def not_passed
      where.not(state: :passed)
    end

    def latest_per_declaration
      join = ParticipantOutcome::NPQ
        .select(Arel.sql("DISTINCT FIRST_VALUE(participant_outcomes.id) OVER (#{latest_participant_outcome_order}) AS latest_id"))

      ParticipantOutcome::NPQ.distinct
        .joins("JOIN (#{join.to_sql}) AS latest_participant_outcomes ON latest_participant_outcomes.latest_id = participant_outcomes.id")
    end

  private

    def latest_participant_outcome_order
      <<~SQL
        PARTITION BY participant_outcomes.participant_declaration_id
          ORDER BY participant_outcomes.created_at DESC
      SQL
    end
  end

  def has_passed?
    return nil if voided?

    passed?
  end

  def has_failed?
    return nil if voided?

    failed?
  end

  def passed_but_not_sent?
    has_passed? && sent_to_qualified_teachers_api_at.nil?
  end

  def failed_but_not_sent?
    has_failed? && sent_to_qualified_teachers_api_at.nil?
  end

  def passed_and_recorded?
    has_passed? && sent_to_qualified_teachers_api_at.present? && qualified_teachers_api_request_successful
  end

  def failed_and_recorded?
    has_failed? && sent_to_qualified_teachers_api_at.present? && qualified_teachers_api_request_successful
  end

  def passed_but_not_recorded?
    has_passed? && sent_to_qualified_teachers_api_at.present? && qualified_teachers_api_request_successful == false
  end

  def failed_but_not_recorded?
    has_failed? && sent_to_qualified_teachers_api_at.present? && qualified_teachers_api_request_successful == false
  end

  def latest_per_declaration?
    self.class.latest_per_declaration.where(id:).any?
  end

  def resend!
    NPQ::ResendParticipantOutcome.new(participant_outcome_id: id).call
  end

private

  def push_outcome_to_big_query
    ParticipantOutcomes::StreamBigQueryJob.perform_later(participant_outcome_id: id)
  end
end
