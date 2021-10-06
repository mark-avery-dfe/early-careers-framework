# frozen_string_literal: true

class CreateInductionTutor < BaseService
  attr_accessor :school, :email, :full_name

  def initialize(school:, email:, full_name:)
    @school = school
    @email = email
    @full_name = full_name
  end

  def call
    ActiveRecord::Base.transaction do
      remove_existing_induction_coordinator

      if (user = User.find_by(email: email))&.induction_coordinator?
        raise if user.full_name != full_name

        user.induction_coordinator_profile.schools << school
      else
        user = User.find_or_create_by!(email: email) do |induction_tutor|
          induction_tutor.full_name = full_name
        end
        InductionCoordinatorProfile.create!(user: user, schools: [school])
      end

      SchoolMailer.nomination_confirmation_email(
        sit_profile: user.induction_coordinator_profile,
        school: school,
        start_url: start_url,
        step_by_step_url: step_by_step_url,
      ).deliver_later
    end
  end

  def start_url
    Rails.application.routes.url_helpers.root_url(
      host: Rails.application.config.domain,
      **UTMService.email(:new_induction_tutor),
    )
  end

  def step_by_step_url
    Rails.application.routes.url_helpers.step_by_step_url(
      host: Rails.application.config.domain,
      **UTMService.email(:new_induction_tutor),
    )
  end

private

  def remove_existing_induction_coordinator
    existing_induction_coordinator = school.induction_coordinators.first
    return if existing_induction_coordinator.nil?

    if existing_induction_coordinator.induction_coordinator_profile.schools.count > 1
      existing_induction_coordinator.induction_coordinator_profile.schools.delete(school)
    elsif existing_induction_coordinator.mentor?
      existing_induction_coordinator.induction_coordinator_profile.destroy!
    else
      existing_induction_coordinator.destroy!
    end
  end
end
