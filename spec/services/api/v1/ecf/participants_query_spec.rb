# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ECF::ParticipantsQuery do
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let(:cohort) { Cohort.current || create(:cohort, :current) }
  let(:partnership) { create(:partnership, lead_provider:, cohort:) }
  let(:participant_profile) { create(:ect_participant_profile) }
  let(:induction_programme) { create(:induction_programme, :fip, partnership:) }
  let!(:induction_record) { create(:induction_record, induction_programme:, participant_profile:) }

  let(:params) { {} }

  subject { described_class.new(lead_provider:, params:) }

  describe "#induction_records" do
    it "returns all induction records" do
      expect(subject.induction_records).to match_array([induction_record])
    end

    context "with preferred identity" do
      let(:preferred_email) { Faker::Internet.email }
      let(:preferred_identity) { create(:participant_identity, :secondary, user: participant_profile.user, email: preferred_email) }
      let!(:another_induction_record) { create(:induction_record, induction_programme:, participant_profile:, preferred_identity:) }
      let(:external_identifier) { participant_profile.participant_identity.external_identifier }
      let(:user_id) { participant_profile.participant_identity.user_id }

      it "returns the user id of the participant identity" do
        expect(subject.induction_records.first.user_id).to eq(user_id)
      end

      it "returns the original external identifier of the participant identity" do
        expect(subject.induction_records.first.external_identifier).to eq(external_identifier)
      end

      it "returns the preferred email" do
        expect(subject.induction_records.first.preferred_identity_email).to eq(preferred_email)
      end
    end

    context "with mentor profile" do
      let(:mentor_participant_profile) { create(:mentor_participant_profile) }
      let(:participant_profile) { create(:ect_participant_profile, mentor_profile_id: mentor_participant_profile.id) }
      let(:mentor_external_identifier) { mentor_participant_profile.participant_identity.external_identifier }
      let(:external_identifier) { participant_profile.participant_identity.external_identifier }
      let(:user_id) { participant_profile.participant_identity.user_id }
      let!(:induction_record) { create(:induction_record, induction_programme:, participant_profile:, mentor_profile_id: mentor_participant_profile.id) }

      it "returns the mentor external identifier" do
        expect(subject.induction_records.first.mentor_external_identifier).to eq(mentor_external_identifier)
      end

      it "returns the user id" do
        expect(subject.induction_records.first.user_id).to eq(user_id)
      end

      it "returns the external identifier" do
        expect(subject.induction_records.first.external_identifier).to eq(external_identifier)
      end
    end

    describe "cohort filter" do
      context "with correct value" do
        let(:params) { { filter: { cohort: cohort.display_name } } }

        it "returns all induction records for the specific cohort" do
          expect(subject.induction_records).to match_array([induction_record])
        end
      end

      context "with multiple values" do
        let(:another_cohort) { create(:cohort, start_year: "2050") }
        let!(:another_partnership) { create(:partnership, cohort: another_cohort, lead_provider:) }
        let(:another_participant_profile) { create(:ect_participant_profile) }
        let(:another_induction_programme) { create(:induction_programme, :fip, partnership: another_partnership) }
        let!(:another_induction_record) { create(:induction_record, induction_programme: another_induction_programme, participant_profile: another_participant_profile) }

        let(:params) { { filter: { cohort: "#{cohort.start_year},#{another_cohort.start_year}" } } }

        it "returns all induction records for the specific cohort" do
          expect(subject.induction_records).to match_array([induction_record, another_induction_record])
        end
      end

      context "with incorrect value" do
        let(:params) { { filter: { cohort: "2017" } } }

        it "returns no induction records" do
          expect(subject.induction_records).to be_empty
        end
      end
    end

    describe "updated_since filter" do
      context "with correct value" do
        let(:another_participant_profile) { create(:ect_participant_profile) }
        let(:another_induction_programme) { create(:induction_programme, :fip, partnership:) }
        let!(:another_induction_record) { create(:induction_record, induction_programme: another_induction_programme, participant_profile: another_participant_profile) }

        let(:params) { { filter: { updated_since: 1.day.ago.iso8601 } } }

        before { another_participant_profile.user.update(updated_at: 4.days.ago.iso8601) }

        it "returns all induction_records for the specific updated_since filter" do
          expect(subject.induction_records).to match_array([induction_record])
        end
      end
    end
  end

  describe "#induction_record" do
    describe "id filter" do
      context "with correct value" do
        let(:another_participant_profile) { create(:ect_participant_profile) }
        let(:another_induction_programme) { create(:induction_programme, :fip, partnership:) }
        let!(:another_induction_record) { create(:induction_record, induction_programme: another_induction_programme, participant_profile: another_participant_profile) }

        let(:params) { { id: another_participant_profile.participant_identity.external_identifier } }

        it "returns a specific induction record" do
          expect(subject.induction_record).to eql(another_induction_record)
        end
      end

      context "with multiple induction records with no end date" do
        let!(:latest_induction_record) do
          travel_to(1.day.ago) do
            create(:induction_record, induction_programme:, participant_profile:, end_date: nil)
          end
        end

        let!(:induction_record) { create(:induction_record, :with_end_date, induction_programme:, participant_profile:) }

        let(:params) { { id: participant_profile.participant_identity.external_identifier } }

        it "returns the induction record with no end date" do
          expect(subject.induction_record).to eql(latest_induction_record)
        end
      end

      context "with multiple induction records starting at different times" do
        let!(:induction_record) do
          create(:induction_record, induction_programme:, participant_profile:, start_date: Time.zone.now)
        end

        let!(:latest_induction_record) do
          create(:induction_record, :future_start_date, induction_programme:, participant_profile:)
        end

        let(:params) { { id: participant_profile.participant_identity.external_identifier } }

        it "returns the induction record with the latest start date" do
          expect(subject.induction_record).to eql(latest_induction_record)
        end
      end

      context "with multiple induction records created at different times" do
        let!(:induction_record) do
          travel_to(1.day.ago) do
            create(:induction_record, induction_programme:, participant_profile:)
          end
        end

        let!(:latest_induction_record) { create(:induction_record, induction_programme:, participant_profile:) }

        let(:params) { { id: participant_profile.participant_identity.external_identifier } }

        it "returns the induction record with the latest timestamp" do
          expect(subject.induction_record).to eql(latest_induction_record)
        end
      end

      context "with incorrect value" do
        let(:params) { { id: SecureRandom.uuid } }

        it "raises an error" do
          expect {
            subject.induction_record
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
