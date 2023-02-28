# frozen_string_literal: true

module Schools
  module AddParticipantWizardSteps
    class WhatWeNeedStep < ::WizardStep
      def next_step
        :name
      end

      def previous_step
        :who
      end
    end
  end
end
