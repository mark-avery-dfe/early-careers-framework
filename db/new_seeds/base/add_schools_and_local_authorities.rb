# frozen_string_literal: true

require Rails.root.join("db/new_seeds/util/seed_utils")

def add_school_to_local_authority(school:, local_authority:, lead_providers:, cohorts:)
  FactoryBot.create(:seed_school_local_authority, school:, local_authority:)
  FactoryBot.create(:seed_induction_coordinator_profile, :with_user).tap do |induction_coordinator_profile|
    FactoryBot.create(:seed_induction_coordinator_profiles_school, induction_coordinator_profile:, school:)

    cohorts.sample(Random.rand(1..cohorts.length)).each do |cohort|
      FactoryBot.create(:seed_school_cohort, school:, cohort:)
    end

    lead_providers.sample.tap do |lead_provider|
      FactoryBot.create(:seed_partnership, :with_delivery_partner, school:, lead_provider:, cohort: cohorts.sample)

      scenarios = Random.rand(1..4).times.map do
        NewSeeds::Scenarios::Participants::Mentors::MentoringMultipleEctsWithSameProvider
          .new(
            school:,
            lead_provider:,
            number: Random.rand(1..4), # number of mentees
          )
          .build
      end

      scenarios.flat_map(&:mentees).map(&:participant_profile).each do |participant_profile|
        Rails.logger.debug("seeding eligibility for #{participant_profile.user.full_name}")

        FactoryBot.create(:seed_ecf_participant_eligibilty, random_weighted_eligibility_trait, participant_profile:)
      end
    end
  end
end

# create some local authorities
local_authorities = FactoryBot.create_list(:local_authority, 10)

cohorts = Cohort.where(start_year: [2021, 2022])
lead_providers = LeadProvider.all

# add some random schools to each LA
local_authorities.each do |local_authority|
  add_school_to_local_authority(school: FactoryBot.create(:seed_school), local_authority:, cohorts:, lead_providers:)
end

# and add some with the old 'test' school format so they're easily findable in dev
1.upto(8) do |i|
  name = "ZZ Test School #{i}"
  add_school_to_local_authority(
    school: FactoryBot.create(:seed_school, name:),
    local_authority: local_authorities.sample,
    cohorts:,
    lead_providers:,
  )
end