# frozen_string_literal: true

module Schools
  module AddParticipants
    class AddController < BaseController
      include AppropriateBodySelection::Controller

      before_action :initialize_wizard, except: :complete
      before_action :data_check, except: :complete

      def complete
        @profile = ParticipantProfile.find(params[:participant_profile_id])
        remove_session_data
      end

      # Appropriate body methods
      def change_appropriate_body
        @wizard.appropriate_body_confirmed = false
        start_appropriate_body_selection
      end

      def save_appropriate_body
        @wizard.appropriate_body_confirmed = false
        @wizard.appropriate_body_id = @appropriate_body_form.body_id

        redirect_to @wizard.show_path_for(step: "check-answers")
      end

      def start_appropriate_body_selection
        super from_path: url_for(action: :show, step: "confirm-appropriate-body"),
              submit_action: :save_appropriate_body,
              school_name: @school.name,
              ask_appointed: false
      end

    private

      def data_check
        unless who_stage_complete?
          remove_session_data
          redirect_to abort_path
        end
      end

      def wizard_class
        AddWizard
      end

      def default_step_name
        :email
      end

      def who_stage_complete?
        @wizard.found_participant_in_dqt? && !@wizard.transfer?
      end
    end
  end
end
