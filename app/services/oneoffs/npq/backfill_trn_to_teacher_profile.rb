# frozen_string_literal: true

module Oneoffs::NPQ
  class BackfillTrnToTeacherProfile
    def migrate
      # locate all TeacherProfiles with empty TRN
      teacher_profiles_without_trns.in_batches.each_record do |profile|
        trns = profile.user.npq_applications
          .where(teacher_reference_number_verified: true)
          .pluck(:teacher_reference_number)
          .uniq

        # check if they are correct
        trn = TeacherReferenceNumber.new(trns.first)
        profile.update!(trn: trn.formatted_trn) if trns.count == 1 && trn.valid?
      end
    end

  private

    def teacher_profiles_without_trns
      TeacherProfile.where(trn: nil)
    end
  end
end
