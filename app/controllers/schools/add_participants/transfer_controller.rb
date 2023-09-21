# frozen_string_literal: true

module Schools
  module AddParticipants
    class TransferController < BaseController
      before_action :initialize_wizard
      before_action :data_check

      def update
        if @form.valid?
          @wizard.save!
          needs_after_transfer_sign_in?
          redirect_to @wizard.next_step_path
        else
          render @wizard.current_step
        end
      end

    private

      def needs_after_transfer_sign_in?
        if @wizard.after_transfer_sign_in_needed
          sign_in(@wizard.current_user, scope: :user)
          if PrivacyPolicy.acceptance_required?(@wizard.current_user)
            PrivacyPolicy.current.accept!(@wizard.current_user)
          end
        end
      end

      def data_check
        if has_already_completed? || !who_stage_complete?
          remove_session_data
          redirect_to abort_path
        end
      end

      def wizard_class
        TransferWizard
      end

      def default_step_name
        "joining-date"
      end

      def has_already_completed?
        @wizard.complete? && step_name.to_sym != :complete
      end

      def who_stage_complete?
        @wizard.found_participant_in_dqt? && @wizard.transfer?
      end
    end
  end
end
