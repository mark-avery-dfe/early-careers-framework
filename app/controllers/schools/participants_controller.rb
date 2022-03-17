# frozen_string_literal: true

class Schools::ParticipantsController < Schools::BaseController
  before_action :set_school_cohort
  before_action :set_participant, except: %i[index email_used]
  before_action :build_mentor_form, only: :edit_mentor
  before_action :set_mentors_added, only: %i[index show]

  def index
    if FeatureFlag.active?(:change_of_circumstances)
      @mentor_categories = CocSetParticipantCategories.call(@school_cohort, current_user, ParticipantProfile::Mentor)
      @ect_categories = CocSetParticipantCategories.call(@school_cohort, current_user, ParticipantProfile::ECT)
      @transferring_in = @ect_categories.transferring_in + @mentor_categories.transferring_in
      @transferring_out = @ect_categories.transferring_out + @mentor_categories.transferring_out
      @transferred = @ect_categories.transferred + @mentor_categories.transferred
    else
      @mentor_categories = SetParticipantCategories.call(@school_cohort, current_user, ParticipantProfile::Mentor)
      @ect_categories = SetParticipantCategories.call(@school_cohort, current_user, ParticipantProfile::ECT)
      @transferred = []
    end

    @withdrawn = @ect_categories.withdrawn + @mentor_categories.withdrawn
    @ineligible = @ect_categories.ineligible + @mentor_categories.ineligible
  end

  def show
    @mentor = @profile.mentor if @profile.ect?
  end

  def edit_name; end

  def update_name
    if @profile.user.update(params.require(:user).permit(:full_name))
      if @profile.ect?
        set_success_message(heading: "The ECT’s name has been updated")
      else
        set_success_message(heading: "The mentor’s name has been updated")
      end
      redirect_to schools_participant_path(id: @profile)
    else
      render "schools/participants/edit_name"
    end
  end

  def edit_email; end

  def update_email
    user = @profile.user
    user.assign_attributes(params.require(:user).permit(:email))
    redirect_to action: :email_used and return if email_used?

    if user.save
      if @profile.ect?
        set_success_message(heading: "The ECT’s email address has been updated")
      else
        set_success_message(heading: "The mentor’s email address has been updated")
      end
      redirect_to schools_participant_path(id: @profile)
    else
      render "schools/participants/edit_email"
    end
  end

  def email_used; end

  def edit_start_term; end

  def update_start_term
    @profile.assign_attributes(params.require(:participant_profile).permit(:start_term))

    if @profile.save
      if @profile.ect?
        set_success_message(heading: "The ECT's start term has been updated")
      else
        set_success_message(heading: "The mentor's start term has been updated")
      end
      redirect_to schools_participant_path(id: @profile)
    else
      render "schools/participants/edit_start_term"
    end
  end

  def edit_mentor; end

  def update_mentor
    if params[:participant_mentor_form].blank?
      build_mentor_form
      @mentor_form.valid?
      render :edit_mentor and return
    end

    @mentor_form = ParticipantMentorForm.new(participant_mentor_form_params.merge(school_id: @school.id, cohort_id: @cohort.id))

    if @mentor_form.valid?
      @profile.update!(mentor_profile: @mentor_form.mentor ? @mentor_form.mentor.mentor_profile : nil)

      flash[:success] = { title: "Success", heading: "The mentor for this participant has been updated" }
      redirect_to schools_participant_path(id: @profile)
    else
      render :edit_mentor
    end
  end

  def remove; end

  def destroy
    ActiveRecord::Base.transaction do
      @profile.withdrawn_record!
      @profile.mentee_profiles.update_all(mentor_profile_id: nil) if @profile.mentor?
      if @profile.request_for_details_sent?
        ParticipantMailer.participant_removed_by_sti(
          participant_profile: @profile,
          sti_profile: current_user.induction_coordinator_profile,
        ).deliver_later
      end
    end

    render :removed
  end

private

  def set_mentors_added
    @mentors_added = @school.mentor_profiles_for(@cohort).any?
  end

  def build_mentor_form
    @mentor_form = ParticipantMentorForm.new(
      mentor_id: @profile.mentor&.id,
      school_id: @school.id,
      cohort_id: @cohort.id,
    )
  end

  def set_participant
    @profile = ParticipantProfile.find(params[:participant_id] || params[:id])
    authorize @profile, policy_class: @profile.policy_class
  end

  def participant_mentor_form_params
    params.require(:participant_mentor_form).permit(:mentor_id)
  end

  def email_used?
    User.where.not(id: @profile.user.id).where(email: @profile.user.email).any?
  end
end
