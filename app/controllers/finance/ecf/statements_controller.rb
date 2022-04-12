# frozen_string_literal: true

require "payment_calculator/npq/payment_calculation"

module Finance
  module ECF
    class StatementsController < BaseController
      def show
        @ecf_lead_provider = lead_provider_scope.find(params[:payment_breakdown_id])
        @cpd_lead_provider = @ecf_lead_provider.cpd_lead_provider

        @statement = @ecf_lead_provider.statements.find_by(name: identifier_to_name)
        @statements = @ecf_lead_provider.statements.upto(@statement).order(deadline_date: :desc)

        aggregator = ParticipantAggregator.new(
          statement: @statement,
          recorder: ParticipantDeclaration::ECF.where(state: %w[paid payable eligible]),
        )

        orchestrator = Finance::ECF::CalculationOrchestrator.new(
          aggregator: aggregator,
          contract: @ecf_lead_provider.call_off_contract,
          statement: @statement,
        )

        @breakdown_started = orchestrator.call(event_type: :started)
        @breakdown_retained_1 = orchestrator.call(event_type: :retained_1)
      end

    private

      def identifier_to_name
        params[:id].humanize.gsub("-", " ")
      end

      def lead_provider_scope
        policy_scope(LeadProvider, policy_scope_class: FinanceProfilePolicy::Scope)
      end
    end
  end
end
