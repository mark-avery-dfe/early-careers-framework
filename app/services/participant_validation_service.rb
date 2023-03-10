# frozen_string_literal: true

class ParticipantValidationService
  attr_reader :trn, :nino, :full_name, :date_of_birth, :config

  def self.validate(trn:, full_name:, date_of_birth:, nino:, config: {})
    new(trn:, full_name:, date_of_birth:, nino:, config:).validate
  end

  def initialize(trn:, full_name:, date_of_birth:, nino: nil, config: {})
    @trn = trn
    @full_name = full_name
    @date_of_birth = date_of_birth
    @nino = nino
    @config = config
  end

  def validate
    validated_record = matching_record

    return if validated_record.nil?

    {
      trn: validated_record["trn"],
      qts: validated_record.dig("qualified_teacher_status", "qts_date").present?,
      active_alert: validated_record["active_alert"],
      previous_participation: previous_participation?(validated_record),
      previous_induction: previous_induction?(validated_record),
      no_induction: validated_record.dig("induction", "start_date").nil?,
      exempt_from_induction: validated_record.dig("induction", "status") == "Exempt",
    }
  end

private

  def previous_participation?(validation_data)
    CheckParticipantPreviousParticipation.call(trn: validation_data["trn"])
  end

  def previous_induction?(validation_data)
    return false if validation_data["induction"].nil?
    return true if validation_data["induction"]["completion_date"].present?
    return false if validation_data["induction"]["start_date"].nil?

    # this should always be a check against 2021 not Cohort.current.start_year
    validation_data["induction"]["start_date"] < ActiveSupport::TimeZone["London"].local(2021, 9, 1)
  end

  def check_first_name_only?
    config[:check_first_name_only]
  end

  def matching_record
    result = DqtRecordCheck.call(trn:, nino:, full_name:, date_of_birth:, check_first_name_only: check_first_name_only?)
    return if result.dqt_record.nil?

    return result.dqt_record if result.total_matched >= 3
  end
end
