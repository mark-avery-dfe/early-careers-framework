# frozen_string_literal: true

module Schools
  module Cohort
    module WizardSteps
      class AppropriateBodyAppointedStep < ::WizardStep
        attr_accessor :appropriate_body_appointed

        validates :appropriate_body_appointed, inclusion: { in: %w[yes no] }

        def self.permitted_params
          %i[appropriate_body_appointed]
        end

        def appropriate_body_appointed?
          appropriate_body_appointed == "yes"
        end

        def complete?
          !appropriate_body_appointed?
        end

        def next_step
          appropriate_body_appointed? ? :appropriate_body_type : :complete
        end
      end
    end
  end
end