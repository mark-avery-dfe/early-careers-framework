# frozen_string_literal: true

cohort_2021 = Cohort.find_by_start_year(2021)
cohort_2022 = Cohort.find_by_start_year(2022)
cohort_2023 = Cohort.find_by_start_year(2023)
cohort_2024 = Cohort.find_by_start_year(2024)

ActiveRecord::Base.transaction do
  (1..4).each do |school_number|
    school = NewSeeds::Scenarios::Schools::School.new(name: "Closing 2021 School #{school_number}", urn: "20210#{school_number}")
                                                 .build
                                                 .with_an_induction_tutor(full_name: "SIT Closing 2021 School #{school_number}", email: "sit-closing-2021-school-#{school_number}@example.com")
                                                 .chosen_fip_and_partnered_in(cohort: cohort_2021)
                                                 .chosen_fip_and_partnered_in(cohort: cohort_2022)
                                                 .chosen_fip_and_partnered_in(cohort: cohort_2023)
                                                 .chosen_fip_and_partnered_in(cohort: cohort_2024)
    (2021..2023).each do |start_year|
      school_cohort = school.school_cohorts[start_year]
      cpd_lead_provider = FactoryBot.create(:seed_cpd_lead_provider,
                                            name: school_cohort.default_induction_programme.partnership.lead_provider.name)

      { "Mentor" => NewSeeds::Scenarios::Participants::Mentors::MentorWithNoEcts,
        "Ect" => NewSeeds::Scenarios::Participants::Ects::Ect }.each do |participant_type, scenario_klass|
        # #{participant_type} with only completed billable declaration
        scenario_klass.new(school_cohort:, full_name: "#{participant_type} #{start_year} School #{school_number} with completed billable declaration")
                      .build
                      .with_induction_record(induction_programme: school_cohort.default_induction_programme)
                      .with_validation_data
                      .with_eligibility.tap do |scenario|
          FactoryBot.create(:seed_ecf_participant_declaration,
                            participant_profile: scenario.participant_profile,
                            user: scenario.user,
                            cpd_lead_provider:,
                            declaration_type: "completed",
                            state: "eligible")
        end

        # #{participant_type} with only completed non-billable declaration
        scenario_klass.new(school_cohort:, full_name: "#{participant_type} #{start_year} School #{school_number} with completed non-billable declaration")
                      .build
                      .with_induction_record(induction_programme: school_cohort.default_induction_programme)
                      .with_validation_data
                      .with_eligibility.tap do |scenario|
          FactoryBot.create(:seed_ecf_participant_declaration,
                            participant_profile: scenario.participant_profile,
                            user: scenario.user,
                            cpd_lead_provider:,
                            declaration_type: "completed",
                            state: "submitted")
        end

        # #{participant_type} with only non-completed billable declaration
        scenario_klass.new(school_cohort:, full_name: "#{participant_type} #{start_year} School #{school_number} with non-completed billable declaration")
                      .build
                      .with_induction_record(induction_programme: school_cohort.default_induction_programme)
                      .with_validation_data
                      .with_eligibility.tap do |scenario|
          FactoryBot.create(:seed_ecf_participant_declaration,
                            participant_profile: scenario.participant_profile,
                            user: scenario.user,
                            cpd_lead_provider:,
                            declaration_type: "started",
                            state: "eligible")
        end

        # #{participant_type} with only non-completed non-billable declaration
        scenario_klass.new(school_cohort:, full_name: "#{participant_type} #{start_year} School #{school_number} with non-completed non-billable declaration")
                      .build
                      .with_induction_record(induction_programme: school_cohort.default_induction_programme)
                      .with_validation_data
                      .with_eligibility.tap do |scenario|
          FactoryBot.create(:seed_ecf_participant_declaration,
                            participant_profile: scenario.participant_profile,
                            user: scenario.user,
                            cpd_lead_provider:,
                            declaration_type: "retained-1",
                            state: "submitted")
        end

        # #{participant_type} with only induction completion date
        scenario_klass.new(school_cohort:, full_name: "#{participant_type} #{start_year} School #{school_number} with induction completion date")
                      .build(induction_completion_date: Date.new(start_year + 1, 8, 31))
                      .with_induction_record(induction_programme: school_cohort.default_induction_programme)
                      .with_validation_data
                      .with_eligibility


      end
    end
  end
end
