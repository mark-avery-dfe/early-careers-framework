# frozen_string_literal: true

module Schools
  module AddParticipants
    module WizardSteps
      class TrnStep < ::WizardStep
        attr_accessor :trn

        validates :trn, presence: true, teacher_reference_number: true

        def self.permitted_params
          %i[
            trn
          ]
        end

        def next_step
          :date_of_birth
        end
      end
    end
  end
end
