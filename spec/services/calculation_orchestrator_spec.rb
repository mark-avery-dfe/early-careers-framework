# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalculationOrchestrator do
  let(:call_off_contract) { create(:call_off_contract) }
  let(:expected_result) do
    {
      service_fees: [{
        service_fee_monthly: 22_288.0,
        service_fee_per_participant: 323.0,
        service_fee_total: 646_349.0,
        service_fee_monthly: 22_287.9,
      },
      output_payments: [
        {
          per_participant: 597.0,
          started: {
            retained_participants: 10,
            per_participant: 119.0,
            subtotal: 1194.0,
          },
        },
        {
          per_participant: 587.0,
          started: {
            retained_participants: 10,
            per_participant: 117.0,
            subtotal: 1175.0,
          },
        },
        {
          per_participant: 580.0,
          started: {
            retained_participants: 10,
            per_participant: 116.0,
            subtotal: 1159.0,
          },
        },
      ],
    }
  end

  before do
    10.times do
      participant_declaration = create(:participant_declaration, lead_provider: call_off_contract.lead_provider)
      create(:participant_declaration, early_career_teacher_profile: participant_declaration.early_career_teacher_profile, lead_provider: call_off_contract.lead_provider)
    end
  end

  context ".call" do
    it "returns the total calculation" do
      expect(described_class.call(lead_provider: call_off_contract.lead_provider, event_type: :started)).to eq(expected_result)
    end
  end
end
