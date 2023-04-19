# frozen_string_literal: true

module Schools
  module Cohort
    module WizardSteps
      class WhatChangesStep < ::WizardStep
        attr_accessor :what_changes

        validates :what_changes, inclusion: { in: ->(form) { form.choices.map(&:id).map(&:to_s) } }

        def self.permitted_params
          %i[what_changes]
        end

        def choices
          [
            OpenStruct.new(id: :change_lead_provider,               name: "Form new partnership with a lead provider and delivery partner"),
            OpenStruct.new(id: :change_to_core_induction_programme, name: "Deliver your own programme using DfE-accredited materials"),
            OpenStruct.new(id: :change_to_design_our_own,           name: "Design and deliver you own programme based on the Early Career Framework (ECF)"),
          ]
        end

        def next_step
          :what_changes_confirmation
        end
      end
    end
  end
end