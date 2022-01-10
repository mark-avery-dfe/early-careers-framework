# frozen_string_literal: true

require "finance/schedule"

FactoryBot.define do
  factory :npq_course do
    sequence(:name) { |n| "NPQ Course #{n}" }
    identifier { (Finance::Schedule::NPQLeadership::IDENTIFIERS + Finance::Schedule::NPQSpecialist::IDENTIFIERS).sample }
  end
end
