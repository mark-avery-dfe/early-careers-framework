# frozen_string_literal: true

require "rails_helper"

require_relative "../../../shared/context/service_record_declaration_params"
require_relative "../../../shared/context/lead_provider_profiles_and_courses"

RSpec.describe RecordDeclarations::Retained::EarlyCareerTeacher do
  include_context "lead provider profiles and courses"
  include_context "service record declaration params"

  let(:retained_params) { params.merge(declaration_type: "retained-1", declaration_date: (milestone_start_date + 1.day).rfc3339) }
  let(:retained_ect_params) { ect_params.merge(declaration_type: "retained-1", declaration_date: (milestone_start_date + 1.day).rfc3339) }
  let(:milestone_start_date) { ect_profile.schedule.milestones[1].start_date }

  before do
    travel_to milestone_start_date + 2.days
  end

  context "when lead providers don't match" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(retained_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when valid user is an early_career_teacher" do
    %w[training-event-attended self-study-material-completed other].each do |evidence_held|
      it "creates a participant and profile declaration" do
        expect { described_class.call(retained_ect_params.merge(evidence_held: evidence_held)) }
            .to change { ParticipantDeclaration.count }.by(1).and change { ProfileDeclaration.count }.by(1)
      end
    end

    it "fails when course is for mentor" do
      params = retained_ect_params.merge({ course_identifier: "ecf-mentor" })
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when user is not a participant" do
    it "does not create a declaration record and raises ParameterMissing for an invalid user_id" do
      expect { described_class.call(induction_coordinator_params) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when declaration type is invalid" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(retained_params.merge(declaration_type: "invalid")) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when evidence held is invalid" do
    it "raises a ParameterMissing error" do
      expect { described_class.call(retained_params.merge(evidence_held: "invalid")) }.to raise_error(ActionController::ParameterMissing)
    end
  end

  context "when declaration date is invalid" do
    it "raises a ParameterMissing error" do
      params = retained_ect_params.merge({ declaration_date: "2021-06-21 08:46:29" })
      expected_msg = /The property '#\/declaration_date' must be a valid RCF3339 date/
      expect { described_class.call(params) }.to raise_error(ActionController::ParameterMissing, expected_msg)
    end
  end
end
