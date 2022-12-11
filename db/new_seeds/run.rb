# frozen_string_literal: true

Dir.glob(Rails.root.join("db/new_seeds/scenarios/**/*.rb")).each do |scenario|
  require scenario
end

def load_base_file(file)
  base_file = Rails.root.join(*(%w[db new_seeds base] << file))

  load(base_file)
end

Rails.logger.info("Seeding database")

# base files are simply ruby scripts we run, they contain
# static data

{
  "importing cohorts" => "add_cohorts.rb",
  "importing schedules" => "add_schedules.rb",
  "importing privacy policy 1.0" => "add_privacy_policy.rb",
  "importing core induction programmes and lead providers" => "add_lead_providers_and_cips.rb",
  "adding users" => "add_users.rb",
}.each do |msg, file|
  Rails.logger.info(msg)
  load_base_file(file)
end

# scenarios are ruby classes that can be used to build more complicated
# structures of data

Rails.logger.info("Adding a user with an appropriate body")
NewSeeds::Scenarios::Users::AppropriateBodyUser.new.build

Rails.logger.info("Adding a finance user")
NewSeeds::Scenarios::Users::FinanceUser.new.build

Rails.logger.info("Building two delivery partner user with two delivery partners each")
2.times { NewSeeds::Scenarios::Users::DeliveryPartnerUser.new(number: 2).build }

# complex scenarios
NewSeeds::Scenarios::Participants::Transfers::FipToFipKeepingOriginalTrainingProvider.new.build
NewSeeds::Scenarios::Participants::Transfers::FipToFipChangingTrainingProvider.new.build
