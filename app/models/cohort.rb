# frozen_string_literal: true

class Cohort < ApplicationRecord
  has_many :schedules, class_name: "Finance::Schedule"
  has_many :partnerships
  has_many :statements
  has_many :call_off_contracts
  has_many :npq_contracts

  def self.current
    # TODO: Register and Partner 262: Figure out how to update current year
    find_by(start_year: 2021)
  end

  def self.next
    year = FeatureFlag.active?(:multiple_cohorts) ? 2022 : 2021

    find_by(start_year: year)
  end

  def start_term_options
    # TODO: Set the terms dependant on dates provided by the team.
    terms = []
    terms << "autumn_#{start_year}" unless start_year == 2021
    terms << "spring_#{start_year + 1}" unless start_year == 2022
    terms << "summer_#{start_year + 1}" unless start_year == 2022
    terms
  end

  def display_name
    start_year.to_s
  end

  def academic_year
    # e.g. 2021/22
    "#{start_year}/#{start_year - 1999}"
  end

  def to_param
    start_year.to_s
  end
end
