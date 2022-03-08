# frozen_string_literal: true

require "rails_helper"

RSpec.describe CocSetParticipantCategories do
  describe "#run" do
    subject(:service) { described_class }

    let(:school) { create(:school) }
    let(:school_cohort) { create(:school_cohort, :cip) }
    let(:cip_programme) { create(:induction_programme, :cip, school_cohort: school_cohort) }
    let(:fip_programme) { create(:induction_programme, :fip, school_cohort: school_cohort) }
    # FIP
    let(:fip_eligible_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_eligible_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_ineligible_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_ineligible_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_contacted_for_info_ect) { create(:ect_participant_profile, :email_sent, request_for_details_sent_at: 5.days.ago, school_cohort: school_cohort) }
    let(:fip_contacted_for_info_mentor) { create(:mentor_participant_profile, :email_sent, request_for_details_sent_at: 5.days.ago, school_cohort: school_cohort) }
    let(:fip_ero_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_ero_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_details_being_checked_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_details_being_checked_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_primary_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, :primary_profile, school_cohort: school_cohort) }
    let(:fip_secondary_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, :secondary_profile, school_cohort: school_cohort) }
    let(:fip_withdrawn_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, training_status: "withdrawn", school_cohort: school_cohort) }
    let(:fip_transferring_in_participant) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:fip_transferring_out_participant) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    # CIP
    let(:cip_eligible_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_eligible_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_ineligible_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_ineligible_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_contacted_for_info_ect) { create(:ect_participant_profile, :email_sent, request_for_details_sent_at: 5.days.ago, school_cohort: school_cohort) }
    let(:cip_contacted_for_info_mentor) { create(:mentor_participant_profile, :email_sent, request_for_details_sent_at: 5.days.ago, school_cohort: school_cohort) }
    let(:cip_ero_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_ero_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_details_being_checked_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_details_being_checked_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_primary_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, :primary_profile, school_cohort: school_cohort) }
    let(:cip_secondary_mentor) { create(:mentor_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, :secondary_profile, school_cohort: school_cohort) }
    let(:cip_withdrawn_ect) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, training_status: "withdrawn", school_cohort: school_cohort) }
    let(:cip_transferring_in_participant) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }
    let(:cip_transferring_out_participant) { create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: school_cohort) }

    let(:fip_participants) do
      [fip_eligible_ect,
       fip_eligible_mentor,
       fip_ineligible_ect,
       fip_ineligible_mentor,
       fip_contacted_for_info_ect,
       fip_contacted_for_info_mentor,
       fip_ero_ect,
       fip_ero_mentor,
       fip_details_being_checked_ect,
       fip_details_being_checked_mentor,
       fip_primary_mentor,
       fip_secondary_mentor,
       fip_withdrawn_ect,
       fip_transferring_in_participant,
       fip_transferring_out_participant]
    end

    let(:cip_participants) do
      [cip_eligible_ect,
       cip_eligible_mentor,
       cip_ineligible_ect,
       cip_ineligible_mentor,
       cip_contacted_for_info_ect,
       cip_contacted_for_info_mentor,
       cip_ero_ect,
       cip_ero_mentor,
       cip_details_being_checked_ect,
       cip_details_being_checked_mentor,
       cip_primary_mentor,
       cip_secondary_mentor,
       cip_withdrawn_ect,
       cip_transferring_in_participant,
       cip_transferring_out_participant]
    end

    context "School with FIP default" do
      let(:induction_coordinator) { create(:induction_coordinator_profile, schools: [school_cohort.school]) }

      before do
        school_cohort.update!(induction_programme_choice: :full_induction_programme, default_induction_programme: fip_programme)
        fip_participants.each do |profile|
          Induction::Enrol.call(participant_profile: profile, induction_programme: fip_programme)
        end
        fip_transferring_in_participant.induction_records.first.update!(start_date: 2.months.from_now)
        fip_transferring_out_participant.induction_records.first.leaving!(1.month.from_now)
        fip_withdrawn_ect.induction_records.first.training_status_withdrawn!

        fip_ineligible_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        fip_ineligible_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        fip_ero_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        fip_ero_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        fip_details_being_checked_ect.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")
        fip_details_being_checked_mentor.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")

        [fip_primary_mentor, fip_secondary_mentor].each do |profile|
          profile.ecf_participant_eligibility.determine_status
          profile.ecf_participant_eligibility.save!
        end

        @ect_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::ECT")
        @mentor_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::Mentor")
      end

      # NOTE: all categories under one spec as otherwise very slow
      it "returns participants in correct category" do
        # eligible
        expect(@ect_categories.eligible).to match_array([fip_eligible_ect, fip_ero_ect])
        expect(@mentor_categories.eligible).to match_array([fip_eligible_mentor, fip_ero_mentor, fip_primary_mentor, fip_secondary_mentor])

        # ineligible
        expect(@ect_categories.ineligible).to match_array(fip_ineligible_ect)
        expect(@mentor_categories.ineligible).to match_array(fip_ineligible_mentor)

        # contacted_for_info
        expect(@ect_categories.contacted_for_info).to match_array(fip_contacted_for_info_ect)
        expect(@mentor_categories.contacted_for_info).to match_array(fip_contacted_for_info_mentor)

        # details_being_checked
        expect(@ect_categories.details_being_checked).to match_array(fip_details_being_checked_ect)
        expect(@mentor_categories.details_being_checked).to match_array(fip_details_being_checked_mentor)

        # withdrawn
        expect(@ect_categories.withdrawn).to match_array(fip_withdrawn_ect)

        # transferring_in
        expect(@ect_categories.transferring_in).to match_array(fip_transferring_in_participant)

        # transferring_out
        expect(@ect_categories.transferring_out).to match_array(fip_transferring_out_participant)
      end
    end

    context "School with CIP default" do
      let(:induction_coordinator) { create(:induction_coordinator_profile, schools: [school_cohort.school]) }

      before do
        school_cohort.update!(default_induction_programme: cip_programme)
        cip_participants.each do |profile|
          Induction::Enrol.call(participant_profile: profile, induction_programme: cip_programme)
        end
        cip_transferring_in_participant.induction_records.first.update!(start_date: 2.months.from_now)
        cip_transferring_out_participant.induction_records.first.leaving!(1.month.from_now)
        cip_withdrawn_ect.induction_records.first.training_status_withdrawn!

        cip_ineligible_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        cip_ineligible_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        cip_ero_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        cip_ero_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        cip_details_being_checked_ect.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")
        cip_details_being_checked_mentor.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")

        [cip_primary_mentor, cip_secondary_mentor].each do |profile|
          profile.ecf_participant_eligibility.determine_status
          profile.ecf_participant_eligibility.save!
        end

        @ect_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::ECT")
        @mentor_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::Mentor")
      end

      # NOTE: all categories under one spec as otherwise very slow
      it "returns participants in correct category" do
        # eligible
        expect(@ect_categories.eligible).to match_array([cip_eligible_ect, cip_ineligible_ect, cip_ero_ect, cip_details_being_checked_ect])
        expect(@mentor_categories.eligible).to match_array([cip_eligible_mentor, cip_ineligible_mentor, cip_ero_mentor, cip_details_being_checked_mentor, cip_primary_mentor, cip_secondary_mentor])

        # ineligible
        expect(@ect_categories.ineligible).to be_empty
        expect(@mentor_categories.ineligible).to be_empty

        # contacted_for_info
        expect(@ect_categories.contacted_for_info).to match_array([cip_contacted_for_info_ect])
        expect(@mentor_categories.contacted_for_info).to match_array([cip_contacted_for_info_mentor])

        # details_being_checked
        expect(@ect_categories.details_being_checked).to be_empty
        expect(@mentor_categories.details_being_checked).to be_empty

        # withdrawn
        expect(@ect_categories.withdrawn).to match_array(cip_withdrawn_ect)

        # transferring_in
        expect(@ect_categories.transferring_in).to match_array(cip_transferring_in_participant)

        # transferring_out
        expect(@ect_categories.transferring_out).to match_array(cip_transferring_out_participant)
      end
    end

    context "CIP and FIP induction programmes" do
      let(:induction_coordinator) { create(:induction_coordinator_profile, schools: [school_cohort.school]) }

      before do
        school_cohort.update!(default_induction_programme: cip_programme)
        cip_participants.each do |profile|
          Induction::Enrol.call(participant_profile: profile, induction_programme: cip_programme)
        end
        cip_transferring_in_participant.induction_records.first.update!(start_date: 2.months.from_now)
        cip_transferring_out_participant.induction_records.first.leaving!(1.month.from_now)
        cip_withdrawn_ect.induction_records.first.training_status_withdrawn!

        cip_ineligible_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        cip_ineligible_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        cip_ero_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        cip_ero_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        cip_details_being_checked_ect.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")
        cip_details_being_checked_mentor.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")

        [cip_primary_mentor, cip_secondary_mentor].each do |profile|
          profile.ecf_participant_eligibility.determine_status
          profile.ecf_participant_eligibility.save!
        end

        fip_participants.each do |profile|
          Induction::Enrol.call(participant_profile: profile, induction_programme: fip_programme)
        end

        fip_transferring_in_participant.induction_records.first.update!(start_date: 2.months.from_now)
        fip_transferring_out_participant.induction_records.first.leaving!(1.month.from_now)
        fip_withdrawn_ect.induction_records.first.training_status_withdrawn!

        fip_ineligible_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        fip_ineligible_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "active_flags")
        fip_ero_ect.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        fip_ero_mentor.ecf_participant_eligibility.update!(status: "ineligible", reason: "previous_participation")
        fip_details_being_checked_ect.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")
        fip_details_being_checked_mentor.ecf_participant_eligibility.update!(status: "manual_check", reason: "no_qts")

        [fip_primary_mentor, fip_secondary_mentor].each do |profile|
          profile.ecf_participant_eligibility.determine_status
          profile.ecf_participant_eligibility.save!
        end

        @ect_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::ECT")
        @mentor_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::Mentor")
      end

      # NOTE: all categories under one spec as otherwise very slow
      it "returns participants in correct category" do
        # eligible
        expect(@ect_categories.eligible).to match_array([fip_eligible_ect, fip_ero_ect, cip_eligible_ect, cip_ineligible_ect, cip_ero_ect, cip_details_being_checked_ect])
        expect(@mentor_categories.eligible).to match_array([fip_eligible_mentor, fip_ero_mentor, fip_primary_mentor, fip_secondary_mentor, cip_eligible_mentor, cip_ineligible_mentor, cip_ero_mentor, cip_details_being_checked_mentor, cip_primary_mentor, cip_secondary_mentor])

        # ineligible
        expect(@ect_categories.ineligible).to match_array(fip_ineligible_ect)
        expect(@mentor_categories.ineligible).to match_array(fip_ineligible_mentor)

        # contacted_for_info
        expect(@ect_categories.contacted_for_info).to match_array([fip_contacted_for_info_ect, cip_contacted_for_info_ect])
        expect(@mentor_categories.contacted_for_info).to match_array([fip_contacted_for_info_mentor, cip_contacted_for_info_mentor])

        # details_being_checked
        expect(@ect_categories.details_being_checked).to match_array(fip_details_being_checked_ect)
        expect(@mentor_categories.details_being_checked).to match_array(fip_details_being_checked_mentor)

        # withdrawn
        expect(@ect_categories.withdrawn).to match_array([fip_withdrawn_ect, cip_withdrawn_ect])

        # transferring_in
        expect(@ect_categories.transferring_in).to match_array([fip_transferring_in_participant, cip_transferring_in_participant])

        # transferring_out
        expect(@ect_categories.transferring_out).to match_array([fip_transferring_out_participant, cip_transferring_out_participant])
      end
    end

    context "SIT for multiple schools" do
      let(:school_cohorts) { create_list(:school_cohort, 3, :cip) }
      let(:school_cohort) { school_cohorts.first }
      let(:induction_coordinator) { create(:induction_coordinator_profile, schools: school_cohorts.map(&:school)) }

      before do
        cip_participants.each do |profile|
          Induction::Enrol.call(participant_profile: profile, induction_programme: cip_programme)
        end
        cip_transferring_in_participant.induction_records.first.update!(start_date: 2.months.from_now)
        cip_transferring_out_participant.induction_records.first.leaving!(1.month.from_now)
        cip_withdrawn_ect.induction_records.first.training_status_withdrawn!

        @ects = []
        school_cohorts.each do |a_school_cohort|
          programme = create(:induction_programme, :cip, school_cohort: a_school_cohort)
          ect = create(:ect_participant_profile, :ecf_participant_eligibility, :ecf_participant_validation_data, school_cohort: a_school_cohort)
          a_school_cohort.update!(default_induction_programme: programme)
          Induction::Enrol.call(participant_profile: ect, induction_programme: programme)
          @ects << ect
        end
      end

      it "only returns ECTs for the selected school cohort" do
        ect_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::ECT")

        expect(ect_categories.eligible).to match_array [cip_eligible_ect, cip_ineligible_ect, cip_ero_ect, cip_details_being_checked_ect, @ects.first]
        expect(ect_categories.eligible).not_to include(@ects[1], @ects[2], cip_eligible_mentor, cip_ero_mentor)
      end

      it "only returns mentors for the selected school cohort" do
        mentor_categories = service.call(school_cohort, induction_coordinator.user, "ParticipantProfile::Mentor")

        expect(mentor_categories.eligible).to match_array [cip_eligible_mentor, cip_ineligible_mentor, cip_ero_mentor, cip_details_being_checked_mentor, cip_primary_mentor, cip_secondary_mentor]
        expect(mentor_categories.eligible).not_to include(@ects[1], @ects[2], cip_eligible_ect, cip_ero_ect)
      end
    end
  end
end
