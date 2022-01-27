# frozen_string_literal: true

RSpec.shared_examples "a participant withdraw action service" do |with_notification:|
  it_behaves_like "a participant action service"

  it "fails when the reason is invalid" do
    params = given_params.merge({ reason: "wibble" })
    expect { described_class.call(params: params) }.to raise_error(ActionController::ParameterMissing)
  end

  it "creates a withdrawn state and makes the profile withdrawn" do
    expect { described_class.call(params: given_params) }.to change { ParticipantProfileState.count }.by(1)
    expect(user_profile.participant_profile_state).to be_withdrawn
    expect(user_profile).to be_training_status_withdrawn
  end

  it "sends an email to confirm a participant has been withdrawn", if: with_notification do
    mailer = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(SchoolMailer).to receive(:fip_provider_has_withdrawn_a_participant).and_return(mailer)

    described_class.call(params: given_params)

    expect(SchoolMailer).to have_received(:fip_provider_has_withdrawn_a_participant).with(
      withdrawn_participant: user_profile,
      induction_coordinator: user_profile.school.induction_coordinator_profiles.first,
    )
  end

  it "creates a withdrawn state when that user is deferred" do
    ParticipantProfileState.create!(participant_profile: user_profile, state: "deferred")
    expect(user_profile.participant_profile_state.deferred?)
    expect { described_class.call(params: given_params) }.to change { ParticipantProfileState.count }.by(1)
    expect(user_profile.participant_profile_state).to be_withdrawn
    expect(user_profile).to be_training_status_withdrawn
  end

  it "fails when the participant is already withdrawn" do
    described_class.call(params: given_params)
    expect(user_profile.participant_profile_state.withdrawn?)
    expect { described_class.call(params: given_params) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "fails when participant profile is a withdrawn record" do
    user_profile.withdrawn_record!
    expect { described_class.call(params: given_params) }.to raise_error(ActionController::ParameterMissing)
  end
end

RSpec.shared_examples "a participant withdraw action endpoint" do
  let(:parsed_response) { JSON.parse(response.body) }

  it "returns an error when the participant is already withdrawn" do
    2.times { put url, params: params }

    expect(response).not_to be_successful
  end

  context "with an invalid request" do
    context "with invalid reason" do
      context "when reason is blank" do
        before { params[:data][:attributes][:reason] = "" }

        it "returns and error with the reason for the error" do
          put url, params: params

          expect(response).not_to be_successful
          expect(parsed_response.dig("errors", 0, "detail")).to eq("The property '#/reason' must be present and in the list")
        end
      end
    end

    context "when reason is not included in the list" do
      before { params[:data][:attributes][:reason] = "erroneous-reason" }

      it "returns and error with the reason for the error" do
        put url, params: params

        expect(response).not_to be_successful
        expect(parsed_response.dig("errors", 0, "detail")).to eq("The property '#/reason' must be present and in the list")
      end
    end
  end
end
