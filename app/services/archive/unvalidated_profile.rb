# frozen_string_literal: true

module Archive
  class UnvalidatedProfile < ::BaseService
    include Archive::SupportMethods

    def call
      check_profile_can_be_archived!

      data = Archive::ParticipantProfileSerializer.new(participant_profile).serializable_hash[:data]

      ActiveRecord::Base.transaction do
        relic = Archive::Relic.create!(object_type: participant_profile.class.name,
                                       object_id: participant_profile.id,
                                       display_name: user.full_name,
                                       reason:,
                                       data:)
        destroy_profile!(participant_profile) unless keep_original
        relic
      end
    end

  private

    attr_accessor :participant_profile, :user, :reason, :keep_original

    def initialize(participant_profile, reason: "unvalidated/undeclared ECTs 2021 or 2022", keep_original: false)
      @participant_profile = participant_profile
      @user = participant_profile.user
      @reason = reason
      @keep_original = keep_original
    end

    def check_profile_can_be_archived!
      if profile_has_declarations?
        raise ArchiveError, "Profile #{participant_profile.id} has non-voided declarations"
      elsif profile_has_eligibility?
        raise ArchiveError, "Profile #{participant_profile.id} has an eligibility record"
      elsif profile_has_mentees?
        raise ArchiveError, "Profile #{participant_profile.id} has mentees"
      end
    end
  end
end
