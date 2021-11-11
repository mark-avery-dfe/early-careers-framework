# frozen_string_literal: true

module Admin
  module Schools
    class Cohort2020Controller < Admin::BaseController
      skip_after_action :verify_authorized
      skip_after_action :verify_policy_scoped

      def show
        @participant_profiles = policy_scope(ParticipantProfile::ECF, policy_scope_class: ParticipantProfilePolicy::Scope)
                                  .active_record
                                  .where(school_cohort_id: school_cohort.id)
                                  .includes(:user)
                                  .order("users.full_name")
      end

      def new
        @user = User.new
      end

      def create
        @user = User.find_or_initialize_by(params.require(:user).permit(:email))
        @user.full_name = params.dig(:user, :full_name)

        render :new and return unless @user.valid?

        if @user.early_career_teacher?
          @user.errors.add(:base, "A user with this email address is currently participating as an ECT at school with urn #{@user.teacher_profile.current_ecf_profile.school.urn}")
          render :new and return
        end

        EarlyCareerTeachers::Create.call(
          full_name: @user.full_name,
          email: @user.email,
          school_cohort: school_cohort,
          mentor_profile_id: nil,
          year_2020: true,
        )

        set_success_message(title: "Success", heading: "NQT+1 created", content: "")
        redirect_to admin_school_cohort2020_path
      end

    private

      def school
        @school ||= School.friendly.find params[:school_id]
      end

      def school_cohort
        SchoolCohort.find_by(school: school, cohort: Cohort.find_by(start_year: 2020))
      end
    end
  end
end
