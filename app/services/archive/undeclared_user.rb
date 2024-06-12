# frozen_string_literal: true

module Archive
  class UndeclaredUser < ::BaseService
    EXCLUDED_ROLES = %w[
      appropriate_body lead_provider delivery_partner admin finance induction_coordinator npq_participant npq_applicant
    ].freeze

    def call
      check_user_can_be_archived!

      data = Archive::UserSerializer.new(user).serializable_hash[:data]

      ActiveRecord::Base.transaction do
        relic = Archive::Relic.create!(object_type: user.class.name,
                                       object_id: user.id,
                                       display_name: user.full_name,
                                       reason:,
                                       data:)
        destroy_user! unless keep_original
        relic
      end
    end

  private

    attr_accessor :user, :cohort, :reason, :keep_original

    def initialize(user, cohort_year: 2021, reason: "undeclared participants in 2021", keep_original: false)
      @user = user
      @reason = reason
      @cohort = Cohort.find_by(start_year: cohort_year)
      @keep_original = keep_original
    end

    def check_user_can_be_archived!
      if users_excluded_roles.any?
        raise ArchiveError, "User #{user.id} has excluded roles: #{users_excluded_roles.join(',')}"
      elsif other_user_cohorts.any?
        raise ArchiveError, "User #{user.id} is in other cohorts: #{other_user_cohorts.join(',')}"
      elsif user_not_in_2021_cohort?
        raise ArchiveError, "User #{user.id} is not in #{cohort.start_year} cohort"
      elsif user_has_declarations?
        raise ArchiveError, "User #{user.id} has non-voided declarations"
      elsif user_has_mentees?
        raise ArchiveError, "User #{user.id} has mentees"
      elsif user_has_been_transferred?
        raise ArchiveError, "User #{user.id} has transfer records"
      elsif user_has_gai_id?
        raise ArchiveError, "User #{user.id} has a Get an Identity ID"
      elsif user_is_mentor_on_declarations?
        raise ArchiveError, "User #{user.id} is mentor on declarations"
      end
    end

    def other_user_cohorts
      @other_user_cohorts ||= user.participant_profiles.ecf.joins(:schedule).where.not(schedule: { cohort: }).map { |profile| profile.schedule.cohort.start_year }
    end

    def user_not_in_requested_cohort?
      user.participant_profiles.ecf.joins(:schedule).where(schedule: { cohort: }).none?
    end

    def users_excluded_roles
      @users_excluded_roles ||= (user.user_roles & EXCLUDED_ROLES)
    end

    def user_has_declarations?
      profile_ids = user.participant_profiles.pluck(:id)
      # handle bad data case where user_id might be on declarations not associated with the users profiles
      # in this case it doesn't matter whether they're voided or not, removing the user will cause issues.
      ParticipantDeclaration.where.not(state: %w[submitted ineligible voided]).where(participant_profile_id: profile_ids).any? ||
        ParticipantDeclaration.where(user_id: user.id).where.not(participant_profile_id: profile_ids).any?
    end

    def user_has_mentees?
      return false unless user.user_roles.include? "mentor"

      user.teacher_profile.participant_profiles.mentors.any? do |mentor_profile|
        InductionRecord.where(mentor_profile:).any?
      end
    end

    def user_has_been_transferred?
      user.participant_id_changes.any?
    end

    def user_has_gai_id?
      user.get_an_identity_id.present?
    end

    def user_is_mentor_on_declarations?
      ParticipantDeclaration.where(mentor_user_id: user.id).any?
    end

    def destroy_user!
      user.participant_identities.each do |participant_identity|
        participant_identity.participant_profiles.each do |participant_profile|
          destroy_profile_data!(participant_profile)
        end
        participant_identity.destroy!
      end
      user.teacher_profile.destroy!
      user.destroy!
    end

    def destroy_profile_data!(participant_profile)
      DestroyECFProfileData.call(participant_profile:)
    end
  end
end
