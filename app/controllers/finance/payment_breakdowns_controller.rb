# frozen_string_literal: true

module Finance
  class PaymentBreakdownsController < BaseController
    before_action :set_programme_form

    def show
      redirect_to action: :select_programme
    end

    def select_programme; end

    def choose_programme
      render "select_programme" and return unless @choose_programme_form.valid?(:choose_programme)

      if @choose_programme_form.programme == "ecf"
        redirect_to action: :select_provider_ecf
      else
        redirect_to action: :select_provider_npq
      end
    end

    def select_provider_ecf; end

    def choose_provider_ecf
      render "select_provider_ecf" and return unless @choose_programme_form.valid?(:choose_provider)

      lead_provider = LeadProvider.find(@choose_programme_form.provider)

      statement = Finance::Statement::ECF.where(cpd_lead_provider: lead_provider.cpd_lead_provider)
        .order(deadline_date: :desc)
        .first

      redirect_to finance_ecf_payment_breakdown_statement_path(payment_breakdown_id: lead_provider.id, id: statement.name)
    end

    def select_provider_npq; end

    def choose_provider_npq
      render "select_provider_npq" and return unless @choose_programme_form.valid?(:choose_provider)

      redirect_to finance_npq_lead_provider_statement_path(lead_provider_id: @choose_programme_form.provider, id: Finance::Statement::NPQ.payable.first.id)
    end

  private

    def set_programme_form
      @choose_programme_form = Finance::ChoosePaymentBreakdownForm.new(programme_form_params)
    end

    def programme_form_params
      return {} unless params.key?(:finance_choose_payment_breakdown_form)

      params.require(:finance_choose_payment_breakdown_form).permit(:programme, :provider)
    end
  end
end
