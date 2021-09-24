# frozen_string_literal: true

RSpec.shared_examples "a participant declaration service" do
  context "when lead providers don't match" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(given_params.merge(cpd_lead_provider: another_lead_provider)) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  let(:params_with_different_date) do
    given_params.merge({ declaration_date: (cutoff_start_datetime + 1.day + 1.second).rfc3339 })
  end

  it "creates a participant and profile declaration" do
    expect { described_class.call(given_params) }.to change { ParticipantDeclaration.count }.by(1).and change { ProfileDeclaration.count }.by(1)
  end

  it "does not create exact duplicates" do
    expect {
      described_class.call(given_params)
      described_class.call(given_params)
    }.to change { ParticipantDeclaration.count }.by(1).and change { ProfileDeclaration.count }.by(1)
  end

  it "does not create close duplicates and throws an error" do
    expect {
      described_class.call(given_params)
      described_class.call(params_with_different_date)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  context "when user is not a participant" do
    it "does not create a declaration record and raises ParameterMissing for an invalid user_id" do
      expect { described_class.call(induction_coordinator_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when declaration date is invalid" do
    it "raises ParameterMissing error" do
      params = given_params.merge({ declaration_date: "2021-06-21 08:46:29" })
      expected_msg = /The property '#\/declaration_date' must be a valid RCF3339 date/
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing, expected_msg)
    end
  end

  context "when declaration date is in future" do
    it "raised ParameterMissing error" do
      params = given_params.merge({ declaration_date: (Time.zone.now + 100.years).rfc3339(9) })
      expected_msg = /The property '#\/declaration_date' can not declare a future date/
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing, expected_msg)
    end
  end

  context "when declaration date is in the past" do
    it "does not raise ParameterMissing error" do
      params = given_params.merge({ declaration_date: (Time.zone.now - 1.day).rfc3339(9) })
      expect { described_class.call(params) }.to_not raise_error
    end
  end

  context "when declaration date is today" do
    it "does not raise ParameterMissing error" do
      params = given_params.merge({ declaration_date: Time.zone.now.rfc3339(9) })
      expect { described_class.call(params) }.to_not raise_error
    end
  end

  context "when before the milestone start" do
    before do
      travel_to cutoff_start_datetime - 1.day
    end

    it "raises ParameterMissing error" do
      params = given_params.merge({ declaration_date: (cutoff_start_datetime - 1.day).rfc3339 })
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when at the milestone start" do
    before do
      travel_to cutoff_start_datetime
    end

    it "raises ParameterMissing error" do
      params = given_params.merge({ declaration_date: cutoff_start_datetime.rfc3339 })
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when in the middle of milestone" do
    before do
      travel_to cutoff_start_datetime + 2.days
    end

    it "does not raise ParameterMissing error" do
      params = given_params.merge({ declaration_date: (cutoff_start_datetime + 2.days).rfc3339 })
      expect { described_class.call(params) }.to_not raise_error
    end
  end

  context "when at the milestone end" do
    before do
      travel_to cutoff_end_datetime
    end

    it "does not raise ParameterMissing error" do
      params = given_params.merge({ declaration_date: cutoff_end_datetime.rfc3339 })
      expect { described_class.call(params) }.to_not raise_error
    end
  end

  context "when after the milestone start" do
    before do
      travel_to cutoff_end_datetime + 1.day
    end

    it "raises ParameterMissing error" do
      params = given_params.merge({ declaration_date: (cutoff_end_datetime + 1.day).rfc3339 })
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing)
    end
  end
end
