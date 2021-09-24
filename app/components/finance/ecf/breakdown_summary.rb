# frozen_string_literal: true

module Finance
  module ECF
    class BreakdownSummary < BaseComponent
      include FinanceHelper
    # TODO: include revised_target in here somewhere :P

    private

      def initialize(breakdown_summary:)
        @breakdown = breakdown_summary
        @service_fees_participants = @breakdown[:service_fees].map { |params| params[:participants] }.inject(&:+)
        @service_fees_total = @breakdown[:service_fees].map { |params| params[:monthly] }.inject(&:+)
        @output_payment_participants = @breakdown[:output_payments].map { |params| params[:participants] }.inject(&:+)
        @output_payment_total = @breakdown[:output_payments].map { |params| params[:subtotal] }.inject(&:+)
      end
    end
  end
end
