# frozen_string_literal: true

require "payment_calculator/npq/payment_calculation"

module Finance
  module NPQ
    module ParticipantDeclarations
      class VoidedController < BaseController
        def show
          @npq_lead_provider   = lead_provider_scope.find(params[:lead_provider_id])
          @cpd_lead_provider   = @npq_lead_provider.cpd_lead_provider
          @statement           = @cpd_lead_provider.npq_lead_provider.statements.find_by(name: identifier_to_name)
          @voided_declarations = ParticipantDeclaration::NPQ.where(statement: @statement).voided
        end

      private

        def identifier_to_name
          params[:id].humanize.gsub("-", " ")
        end

        def lead_provider_scope
          policy_scope(NPQLeadProvider, policy_scope_class: FinanceProfilePolicy::Scope)
        end
      end
    end
  end
end
