# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::NPQApplicationsQuery, :with_default_schedules do
  let(:school_urn) { "123456" }
  let(:cohort) { Cohort.current || create(:cohort, :current) }
  let(:pre_2021_cohort) { create(:cohort, start_year: 2020) }
  let(:npq_lead_provider) { create(:npq_lead_provider) }
  let(:other_npq_lead_provider) { create(:npq_lead_provider) }
  let(:params) { {} }
  let(:instance) { described_class.new(npq_lead_provider:, params:) }

  describe "#applications" do
    let(:oldest_application) { travel_to(1.month.ago) { create(:npq_application, npq_lead_provider:, school_urn:, cohort:) } }
    let(:newest_application) { create(:npq_application, npq_lead_provider:, school_urn:, cohort:) }
    let!(:applications) { [newest_application, oldest_application] }
    let!(:other_applications) { create_list(:npq_application, 2, npq_lead_provider: other_npq_lead_provider, school_urn:, cohort:) }
    let!(:pre_2021_applications) { create_list(:npq_application, 2, npq_lead_provider:, school_urn:, cohort: pre_2021_cohort) }

    subject(:query_applications) { instance.applications }

    it { is_expected.to match_array(applications) }

    describe "updated_since filter" do
      let(:updated_since) { (oldest_application.created_at + 1.day).iso8601 }
      let(:params) { { filter: { updated_since: } } }

      it { is_expected.to contain_exactly(newest_application) }

      context "when passed an invalid value" do
        let(:params) { { filter: { updated_since: "2022" } } }

        it { expect { query_applications }.to raise_error(Api::Errors::InvalidDatetimeError) }
      end

      context "when passed a URL encoded date" do
        let(:params) { { filter: { updated_since: CGI.escape(updated_since) } } }

        it { is_expected.to contain_exactly(newest_application) }
      end
    end

    describe "participant_id filter" do
      let(:user) { create(:user) }
      let!(:participant_applications) { create_list(:npq_application, 2, npq_lead_provider:, school_urn:, user:) }
      let(:params) { { filter: { participant_id: user.id } } }

      it { is_expected.to match_array(participant_applications) }
    end

    describe "cohort filter" do
      let(:params) { { filter: { cohort: cohort.start_year } } }

      it { is_expected.to match_array(applications) }

      context "when filtering by multiple cohorts" do
        let(:params) { { filter: { cohort: [cohort.start_year, pre_2021_cohort.start_year].join(",") } } }

        it { is_expected.to match_array(applications + pre_2021_applications) }
      end

      context "when passed an invalid value" do
        let(:params) { { filter: { cohort: "cohort1" } } }

        it { is_expected.to be_empty }
      end
    end

    describe "sorting" do
      it "orders by application created_at ascending by default" do
        expect(query_applications.map(&:id)).to eq([oldest_application.id, newest_application.id])
      end
    end
  end
end