# frozen_string_literal: true

module Admin::Participants
  class ChangeCohortController < Admin::BaseController
    def edit
      @participant_profile = retrieve_participant_profile
      @relevant_induction_record = Induction::FindBy.call(participant_profile: @participant_profile)

      @amend_participant_cohort = Induction::AmendParticipantCohort.new
    end

    def update
      @participant_profile = retrieve_participant_profile
      @relevant_induction_record = Induction::FindBy.call(participant_profile: @participant_profile)

      @amend_participant_cohort = Induction::AmendParticipantCohort.new(
        { **default_amend_participant_cohort_attributes, **amend_participant_cohort_params }.symbolize_keys,
      )

      if @amend_participant_cohort.save
        flash[:success] = {
          title: "Cohort changed successfully",
          content: "#{@participant_profile.user.full_name}'s cohort was changed to #{@amend_participant_cohort.target_cohort_start_year}",
        }
        redirect_to(admin_participant_path(@participant_profile))
      else
        render(:edit)
      end
    end

  private

    def default_amend_participant_cohort_attributes
      {
        participant_profile: @participant_profile,
        source_cohort_start_year: @relevant_induction_record.cohort.start_year,
      }
    end

    def amend_participant_cohort_params
      params.require(:induction_amend_participant_cohort).permit(:target_cohort_start_year)
    end

    def retrieve_participant_profile
      policy_scope(ParticipantProfile).find(params[:participant_id]).tap do |participant_profile|
        authorize participant_profile, policy_class: participant_profile.policy_class
      end
    end
  end
end
