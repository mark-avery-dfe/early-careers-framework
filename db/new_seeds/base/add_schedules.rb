# frozen_string_literal: true

Rails.logger.info("Importing schedules")

if Rails.env.test?
  # NOTE: this is a copy of spec/support/with_default_schedules.rb, both will
  #       exist while doing the transition

  end_year = Date.current.month < 9 ? Date.current.year : Date.current.year + 1
  (2020..end_year).each do |start_year|
    cohort = Cohort.find_by(start_year:) || FactoryBot.create(:cohort, start_year:)
    Finance::Schedule::ECF.default_for(cohort:) || FactoryBot.create(:ecf_schedule, cohort:)

    {
      npq_specialist_schedule: %w[npq-specialist-spring npq-specialist-autumn],
      npq_leadership_schedule: %w[npq-leadership-spring npq-leadership-autumn],
      npq_aso_schedule:        %w[npq-aso-december],
      npq_ehco_schedule:       %w[npq-ehco-november npq-ehco-december npq-ehco-march npq-ehco-june],
    }.each do |schedule_type, schedule_identifiers|
      schedule_identifiers.each do |schedule_identifier|
        Finance::Schedule.find_by(cohort:, schedule_identifier:) || FactoryBot.create(schedule_type, cohort:, schedule_identifier:)
      end
    end
  end
else
  Importers::CreateSchedule.new(path_to_csv: Rails.root.join("db/data/schedules/schedules.csv")).call
end
