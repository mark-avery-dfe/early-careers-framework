# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordDeclarations::Base do
  let(:cpd_lead_provider)       { create(:cpd_lead_provider, :with_lead_provider) }
  let(:cohort)                  { create(:cohort, start_year: Time.zone.today.year) }
  let(:school)                  { create(:school) }
  let(:school_cohort)           { create(:school_cohort, school: school, cohort: cohort) }
  let(:declaration_date)        { Time.zone.parse("2021-11-02") }
  let(:declaration_type)        { "started" }
  let(:user)                    { create(:user) }
  let(:teacher_profile)         { create(:teacher_profile, user: user) }
  let!(:ect_participant_profile) { create(:ect_participant_profile, school_cohort: school_cohort, teacher_profile: teacher_profile) }
  let!(:partnership) { create(:partnership, lead_provider: cpd_lead_provider.lead_provider, cohort: cohort, school: school) }

  let(:induction_programme) { create(:induction_programme, partnership: partnership) }

  let!(:induction_record) do
    Induction::Enrol.call(participant_profile: ect_participant_profile, induction_programme: induction_programme)
  end

  let(:params) do
    {
      participant_id: ect_participant_profile.user_id,
      course_identifier: "ecf-induction",
      cpd_lead_provider: cpd_lead_provider,
      declaration_date: declaration_date.rfc3339,
      declaration_type: declaration_type,
    }
  end

  describe "#call" do
    subject(:record_declaration) { RecordDeclarations::Started::EarlyCareerTeacher.call(params: params) }

    context "when no duplicate participant exists" do
      context "when the participant is fundable" do
        let!(:ecf_participant_eligibility) { create(:ecf_participant_eligibility, :eligible, participant_profile: ect_participant_profile) }

        it "transitions the declaration to eligible" do
          expect { record_declaration }
            .to change(ect_participant_profile.reload.participant_declarations.for_lead_provider(cpd_lead_provider).eligible, :count)
            .from(0).to(1)
        end
      end

      context "when the participant is not fundable" do
        let!(:ecf_participant_eligibility) { create(:ecf_participant_eligibility, :ineligible, participant_profile: ect_participant_profile) }

        it "transitions the declaration to submitted" do
          expect { record_declaration }
            .to change(ect_participant_profile.reload.participant_declarations.for_lead_provider(cpd_lead_provider).submitted, :count)
                  .from(0).to(1)
        end
      end

      context "when a similar declaration has been voided" do
        let!(:void_declaration) do
          VoidParticipantDeclaration.new(
            cpd_lead_provider: cpd_lead_provider,
            id: JSON.parse(RecordDeclarations::Started::EarlyCareerTeacher.call(params: params.merge(declaration_date: (declaration_date + 1.day).rfc3339))).dig("data", "id"),
          ).call
        end

        it "allows to re-send a new declaration" do
          expect(ParticipantDeclaration.find(JSON.parse(record_declaration).dig("data", "id"))).to be_submitted
        end
      end
    end

    context "when a duplicated participant exist" do
      let(:original_ect_participant_profile) do
        create(:ect_participant_profile, school_cohort: school_cohort).tap do |participant_profile|
          participant_profile.teacher_profile.update!(trn: ect_participant_profile.teacher_profile.trn)
          Induction::Enrol.call(participant_profile: participant_profile, induction_programme: induction_programme)
        end
      end

      let(:record_original_declaration) do
        RecordDeclarations::Started::EarlyCareerTeacher
          .call(params: params.except(:participant_id)
                  .merge(participant_id: original_ect_participant_profile.user_id))
      end

      let(:original_participant_declaration) { ParticipantDeclaration.find(JSON.parse(record_original_declaration).dig("data", "id")) }

      before { record_original_declaration }

      it "transitions the declaration to ineligible", :aggregate_failures do
        duplicate_participant_declaration = ParticipantDeclaration.find(JSON.parse(record_declaration).dig("data", "id"))

        expect(original_participant_declaration.supersedes).to eq([duplicate_participant_declaration])
        expect(duplicate_participant_declaration.declaration_states.pluck(:state)).to eq(%w[submitted ineligible])
        expect(duplicate_participant_declaration.declaration_states.find_by!(state: "ineligible")).to be_duplicate
      end
    end
  end

  describe "#call" do
    let(:klass) do
      Class.new(described_class) do
        def self.valid_declaration_types
          %w[started completed retained-1 retained-2 retained-3 retained-4]
        end

        def self.valid_courses
          %w[ecf-induction]
        end

        def self.declaration_model
          ParticipantDeclaration::ECF
        end

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        def user_profile
          user.participant_profiles[0]
        end

        def matches_lead_provider?
          true
        end
      end
    end

    subject do
      klass.new(
        params: {
          course_identifier: "ecf-induction",
          cpd_lead_provider: cpd_lead_provider,
          declaration_date: declaration_date.rfc3339,
          declaration_type: "started",
          participant_id: user.id,
        },
      )
    end

    context "when milestone has null milestone_date" do
      before do
        Finance::Milestone.find_by(declaration_type: "started").update!(milestone_date: nil)
      end

      it "does not have errors on milestone_date" do
        expect { subject.call }.not_to raise_error
      end
    end

    context "when declaration_type does not exist for the schedule" do
      before do
        ect_participant_profile.schedule.milestones.find_by(declaration_type: "retained-4").destroy
      end

      subject do
        klass.new(
          params: {
            course_identifier: "ecf-induction",
            cpd_lead_provider: cpd_lead_provider,
            declaration_date: 10.days.ago.iso8601,
            declaration_type: "retained-4",
            participant_id: user.id,
          },
        )
      end

      it "returns an error" do
        expect { subject.call }.to raise_error(ActionController::ParameterMissing, /#\/declaration_type does not exist for this schedule/)
      end
    end

    context "when an existing declaration is in payable state" do
      let!(:existing_declaration) do
        create(
          :ect_participant_declaration,
          :payable,
          cpd_lead_provider: cpd_lead_provider,
          user: user,
          participant_profile: ect_participant_profile,
          declaration_date: declaration_date,
        )
      end

      it "does add another declaration" do
        expect { subject.call }.to change { ParticipantDeclaration.count }.by(1)
      end

      it "marks any further declarations as ineligible" do
        subject.call

        new_declaration = ParticipantDeclaration.order(created_at: :asc).last
        expect(new_declaration.state).to eql("ineligible")
      end

      it "does not change the state of the original declaration" do
        expect { subject.call }.not_to change { existing_declaration.reload.state }
      end
    end
  end
end
