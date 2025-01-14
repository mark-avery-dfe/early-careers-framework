# frozen_string_literal: true

require "rails_helper"

RSpec.describe Participants::CheckAndSetCompletionDate do
  let(:participant_profile) { create(:seed_ect_participant_profile, :valid, induction_start_date:) }
  let!(:induction_record) do
    create(
      :seed_induction_record,
      :with_induction_programme,
      :with_schedule,
      participant_profile:,
    )
  end
  let(:trn) { participant_profile.teacher_profile.trn }
  let(:completion_date) { 1.month.ago.to_date }
  let(:start_date) { 2.months.ago.to_date }
  let(:induction_start_date) { start_date }
  let(:dqt_induction_record) do
    { "endDate" => completion_date,
      "periods" => [
        { "startDate" => start_date,
          "endDate" => start_date + 1.week },
        { "startDate" => start_date + 1.week,
          "endDate" => start_date + 2.weeks },
      ] }
  end

  subject(:service_call) { described_class.call(participant_profile:) }

  describe "#call" do
    before do
      allow(DQT::GetInductionRecord).to receive(:call).with(trn:).and_return(dqt_induction_record)
    end

    context "when the participant already have a completion date" do
      let(:induction_completion_date) { 2.months.ago.to_date }

      before do
        participant_profile.update!(induction_completion_date:)
        service_call
      end

      it "do not re-complete the participant" do
        expect(participant_profile.induction_completion_date).to eq induction_completion_date
      end
    end

    context "when DQT provides a completion date" do
      it "complete the participant with the latest induction period" do
        service_call
        expect(participant_profile.induction_completion_date).to eq(start_date + 2.weeks)
      end
    end

    context "when DQT does not provide a completion date" do
      let(:completion_date) { nil }

      it "does not set a completion date" do
        service_call
        expect(participant_profile.induction_completion_date).to be_nil
      end
    end

    context "when the participant is not an ECT" do
      let(:participant_profile) { create(:seed_mentor_participant_profile, :valid) }

      it "does not set a completion date" do
        service_call
        expect(participant_profile.induction_completion_date).to be_nil
      end
    end

    context "when start dates are matching" do
      it "does not record inconsistencies" do
        expect { service_call }.not_to change { ParticipantProfileStartDateInconsistency.count }.from(0)
      end
    end

    context "when start dates are not matching" do
      let(:induction_start_date) { 10.months.ago.to_date }

      it "records inconsistency" do
        expect { service_call }.to change { ParticipantProfileStartDateInconsistency.count }.from(0).to(1)
      end

      context "when same inconsistency is processed twice" do
        it "records only one inconsistency" do
          expect {
            service_call
            service_call
          }.to change { ParticipantProfileStartDateInconsistency.count }.from(0).to(1)
        end
      end
    end

    context "when completion dates are matching" do
      it "does not record inconsistencies" do
        expect { service_call }.not_to change { ParticipantProfileCompletionDateInconsistency.count }.from(0)
      end
    end

    context "when completion dates are not matching" do
      let(:induction_completion_date) { 2.months.ago.to_date }

      before do
        participant_profile.update!(induction_completion_date:)
      end

      it "records inconsistency" do
        expect { service_call }.to change { ParticipantProfileCompletionDateInconsistency.count }.from(0).to(1)
      end

      context "when same inconsistency is processed twice" do
        it "records only one inconsistency" do
          expect {
            service_call
            service_call
          }.to change { ParticipantProfileCompletionDateInconsistency.count }.from(0).to(1)
        end
      end
    end
  end
end
