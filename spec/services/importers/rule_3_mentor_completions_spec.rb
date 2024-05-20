# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe Importers::Rule3MentorCompletions do
  let!(:mentor_1) { create(:seed_mentor_participant_profile, :valid) }
  let!(:mentor_2) { create(:seed_mentor_participant_profile, :valid) }
  let!(:mentor_3) { create(:seed_mentor_participant_profile, :valid) }
  let!(:ect) { create(:seed_ect_participant_profile, :valid) }
  let(:default_completion_date) { Date.new(2024, 7, 31) }
  let(:completion_date) { nil }
  let(:completion_reason) { ParticipantProfile::Mentor.mentor_completion_reasons[:started_not_completed] }

  let(:csv_data) do
    CSV.parse(<<~ROWS, headers: true)
      participant_profile_id
      #{mentor_1.id}
      #{mentor_2.id}
      #{ect.id}
    ROWS
  end

  let(:bad_csv_data) do
    CSV.parse("wigwam,coconut,parsnip", headers: true)
  end

  subject(:service) { described_class }

  describe ".call" do
    before do
      allow_any_instance_of(service).to receive(:rows).and_return(csv_data)

      args = {
        path_to_source_file: Rails.root,
        completion_date:,
      }.compact

      service.call(**args)
      mentor_1.reload
      mentor_2.reload
      mentor_3.reload
      ect.reload
    end

    it "sets the default completion date for the mentors in the csv file" do
      expect(mentor_1.mentor_completion_date).to eq default_completion_date
      expect(mentor_2.mentor_completion_date).to eq default_completion_date
    end

    it "sets the completion reason for the mentors in the csv file" do
      expect(mentor_1.mentor_completion_reason).to eq completion_reason
      expect(mentor_2.mentor_completion_reason).to eq completion_reason
    end

    context "when the mentor already has a completion date" do
      let(:previous_completion_date) { 1.month.ago.to_date }
      let(:previous_completion_reason) { ParticipantProfile::Mentor.mentor_completion_reasons[:completed_declaration_received] }

      before do
        mentor_2.update!(mentor_completion_date: previous_completion_date, mentor_completion_reason: previous_completion_reason)
      end

      it "does not update the mentor" do
        expect(mentor_2.mentor_completion_date).to eq previous_completion_date
        expect(mentor_2.mentor_completion_reason).to eq previous_completion_reason
      end
    end

    context "when the mentor is not in the csv file" do
      it "does not update the mentor" do
        expect(mentor_3.mentor_completion_date).to be_nil
        expect(mentor_3.mentor_completion_reason).to be_nil
      end
    end

    context "when the participant_profile_id is not a mentor profile" do
      it "does not modify the profile" do
        expect(ect.mentor_completion_date).to be_nil
        expect(ect.mentor_completion_reason).to be_nil
      end
    end

    context "when a completion date is supplied" do
      let(:completion_date) { 10.days.ago.to_date }

      it "sets the completion date for the mentors in the csv file" do
        expect(mentor_1.mentor_completion_date).to eq completion_date
        expect(mentor_2.mentor_completion_date).to eq completion_date
      end
    end
  end

  describe "when the expected csv headers are not found" do
    before do
      allow_any_instance_of(service).to receive(:rows).and_return(bad_csv_data)
    end

    it "raises an error" do
      expect {
        service.call(path_to_source_file: Rails.root, completion_date:)
      }.to raise_error(NameError, "Cannot find expected column headers")
    end
  end
end
