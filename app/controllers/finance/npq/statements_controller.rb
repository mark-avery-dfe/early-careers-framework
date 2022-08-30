# frozen_string_literal: true

module Finance
  module NPQ
    class StatementsController < BaseController
      def show
        @npq_lead_provider = lead_provider_scope.find(params[:lead_provider_id])
        @cpd_lead_provider = @npq_lead_provider.cpd_lead_provider
        @statement         = @cpd_lead_provider.npq_lead_provider.statements.find_by(name: identifier_to_name)
        @statements        = @npq_lead_provider.statements.upto_current.order(payment_date: :desc)
        @npq_contracts     = @npq_lead_provider.npq_contracts.where(version: @statement.contract_version).order(course_identifier: :asc)

        @calculator = StatementCalculator.new(statement: @statement)
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
