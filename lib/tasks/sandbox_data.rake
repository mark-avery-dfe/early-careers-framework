# frozen_string_literal: true

namespace :lead_provider do
  desc "create seed mentors for API testing"
  task seed_mentors: :environment do
    logger = Logger.new($stdout)
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end

    providers_names = ["Capita", "Teach First", "UCL", "Best Practice Network", "Ambition", "Education Development Trust"]
    cohort_2021 = Cohort.find_by!(start_year: "2021")

    providers_names.each_with_index do |provider_name, index|
      logger.info("Generating seed mentors for '#{provider_name}'...")
      lead_provider = LeadProvider.find_by!(name: provider_name)
      school = create_school_and_associations(lead_provider, cohort_2021, index)
      generate_mentors(lead_provider, school, cohort_2021, logger)
    end
  end
end

def generate_mentors(lead_provider, school, cohort, logger)
  existing_count = User.mentors_for_lead_provider(lead_provider).count
  10.times do
    mentor = User.create!(full_name: Faker::Name.name, email: Faker::Internet.email)
    MentorProfile.create!(user: mentor, school: school, cohort: cohort)
    logger.info(" Mentor with user_id #{mentor.id} generated")
  end
  new_count = User.mentors_for_lead_provider(lead_provider).count
  logger.info(" Before: #{existing_count}, after: #{new_count}")
end

def create_school_and_associations(lead_provider, cohort, index)
  school = School.find_by!(
    urn: sprintf("%06d", (10_000 + index)),
  ) do |s|
    s.name = Faker::Company.name
    s.address_line1 = Faker::Address.street_address
    s.postcode = Faker::Address.postcode
  end

  Partnership.find_by!(
    school: school,
    lead_provider: lead_provider,
    cohort: cohort,
  ) do |partnership|
    partnership.delivery_partner = DeliveryPartner.create!(name: Faker::Company.name)
  end

  SchoolCohort.find_by!(school: school, cohort: cohort, induction_programme_choice: "full_induction_programme")

  school
end
