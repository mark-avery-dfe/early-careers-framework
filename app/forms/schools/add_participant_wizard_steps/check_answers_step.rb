# frozen_string_literal: true

module Schools
  module AddParticipantWizardSteps
    class CheckAnswersStep < ::WizardStep
      def before_render
        wizard.set_return_point(:check_answers)
      end

      def next_step
        :confirmation
      end

      def previous_step
        :start_date
      end

      def complete?
        true
      end
    end
  end
end
