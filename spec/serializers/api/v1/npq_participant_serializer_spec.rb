# frozen_string_literal: true

require "rails_helper"

module Api
  module V1
    RSpec.describe NPQParticipantSer  ializer do
      describe "serialization" do
        let(:participant) { create(:user) }

        describe "multiple providers" do
          let!(:schedule) { create(:npq_leadership_schedule) }
          let!(:participant) { create(:user) }
          let!(:identity) { create(:participant_identity, user: participant) }

          let(:cpd_provider_one) { create(:cpd_lead_provider) }
          let(:cpd_provider_two) { create(:cpd_lead_provider) }
          let(:provider_one) { create(:npq_lead_provider, cpd_lead_provider: cpd_provider_one) }
          let(:provider_two) { create(:npq_lead_provider, cpd_lead_provider: cpd_provider_two) }
          let(:course_one) { create(:npq_course, identifier: "npq-headship") }
          let(:course_two) { create(:npq_course, identifier: "npq-senior-leadership") }

          let!(:application_one) { create(:npq_application, :accepted, npq_lead_provider: provider_one, npq_course: course_one, participant_identity: identity) }
          let!(:application_two) { create(:npq_application, :accepted, npq_lead_provider: provider_two, npq_course: course_two, participant_identity: identity) }

          it "does not leak course info when given a provider param" do
            result = NPQParticipantSerializer.new(participant, params: { cpd_lead_provider: provider_one.cpd_lead_provider }).serializable_hash

            expect(result[:data][:attributes][:npq_courses]).to eq %w[npq-headship]
          end

          describe "funded places" do
            context "when feature flag `npq_capping` is inactive" do
              before { FeatureFlag.deactivate(:npq_capping) }

              it "does not return the funded places" do
                result = NPQParticipantSerializer.new(participant, params: { cpd_lead_provider: provider_one.cpd_lead_provider }).serializable_hash

                expect(result[:data][:attributes]).not_to include(:funded_places)
              end
            end

            context "when feature flag `npq_capping` is active" do
              before { FeatureFlag.activate(:npq_capping) }

              it "returns the funded places" do
                application_one.update!(funded_place: true)
                result = NPQParticipantSerializer.new(participant, params: { cpd_lead_provider: provider_one.cpd_lead_provider }).serializable_hash

                expect(result[:data][:attributes][:funded_places]).to eq [
                  {
                    "npq_course": "npq-headship",
                    "funded_place:": true,
                    "npq_application_id": application_one.id,
                  },
                ]
              end
            end
          end

          it "does not leak course info when given no provider param" do
            result = NPQParticipantSerializer.new(participant).serializable_hash
            expect(result[:data][:attributes][:npq_courses]).to eq []
          end
        end

        it "includes updated_at" do
          result = NPQParticipantSerializer.new(participant).serializable_hash
          expect(result[:data][:attributes][:updated_at]).to eq participant.updated_at.rfc3339
        end
      end
    end
  end
end
