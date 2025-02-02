# frozen_string_literal: true

describe Oneoffs::NPQ::MigrateDeclarationsBetweenStatements do
  let(:to_statement_updates) { {} }
  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_npq_lead_provider) }
  let(:npq_lead_provider) { cpd_lead_provider.npq_lead_provider }
  let(:from_statement) { create(:npq_statement, name: "April 2023", cpd_lead_provider:, cohort:, output_fee: true) }
  let(:to_statement) { create(:npq_statement, :next_output_fee, name: "May 2023", cpd_lead_provider:, cohort:) }
  let(:from_statement_name) { from_statement.name }
  let(:to_statement_name) { to_statement.name }
  let(:from_statement_output_fee) { false }
  let(:cohort) { Cohort.current }
  let(:restrict_to_lead_providers) { nil }
  let(:restrict_to_declaration_types) { nil }

  let(:instance) { described_class.new(cohort:, from_statement_name:, to_statement_name:, from_statement_output_fee:, to_statement_updates:, restrict_to_lead_providers:, restrict_to_declaration_types:) }

  before { allow(Rails.logger).to receive(:info) }

  describe "#migrate" do
    let(:dry_run) { false }

    subject(:migrate) { instance.migrate(dry_run:) }

    it { is_expected.to eq(instance.recorded_info) }

    it "sets output_fee to false on the from statements" do
      expect { migrate }.to change { from_statement.reload.output_fee }.to(false)
    end

    it "does not change the to statements" do
      expect { migrate }.not_to change { to_statement.reload.output_fee }
    end

    context "when there are declarations" do
      let(:declaration) { create(:npq_participant_declaration, :payable, cohort:, cpd_lead_provider:, declaration_type: :started) }
      let(:from_statement) { declaration.statements.first }

      let(:cpd_lead_provider2) { declaration2.cpd_lead_provider }
      let(:npq_lead_provider2) { cpd_lead_provider2.npq_lead_provider }
      let(:declaration2) { create(:npq_participant_declaration, :payable, cohort:, declaration_type: :"retained-1") }
      let!(:from_statement2) { declaration2.statements.first.tap { |s| s.update!(name: from_statement.name) } }
      let!(:to_statement2) { create(:npq_statement, :next_output_fee, name: to_statement.name, cpd_lead_provider: cpd_lead_provider2, cohort:) }

      let(:declarations) { [declaration1, declaration2] }

      it "migrates them to the new statement" do
        migrate

        expect(declaration.statement_line_items.map(&:statement)).to all(eq(to_statement))
        expect(declaration2.statement_line_items.map(&:statement)).to all(eq(to_statement2))
      end

      it "records information" do
        migrate

        expect(instance).to have_recorded_info([
          "Migrating declarations from #{from_statement_name} to #{to_statement_name} for 2 providers",
          "Migrating 1 declarations for #{npq_lead_provider.name}",
          "Migrating 1 declarations for #{npq_lead_provider2.name}",
        ])
      end

      context "when from_statement_output_fee result in no changes" do
        let(:from_statement_output_fee) { from_statement.output_fee }

        it { expect { migrate }.not_to change { from_statement.reload.output_fee } }
      end

      context "when restrict_to_lead_providers is provided" do
        let(:restrict_to_lead_providers) { [npq_lead_provider] }

        it "migrates only the declarations for the given lead provider to the new statement" do
          migrate

          expect(declaration.statement_line_items.map(&:statement)).to all(eq(to_statement))
          expect(declaration2.statement_line_items.map(&:statement)).to all(eq(from_statement2))
        end

        it "records information" do
          migrate

          expect(instance).to have_recorded_info([
            "Migrating declarations from #{from_statement_name} to #{to_statement_name} for 1 providers",
            "Migrating 1 declarations for #{npq_lead_provider.name}",
          ])
        end
      end

      context "when restrict_to_declaration_types is provided" do
        let(:restrict_to_declaration_types) { [:started] }

        it "migrates only the declarations with the given declaration type" do
          migrate

          expect(declaration.statement_line_items.map(&:statement)).to all(eq(to_statement))
          expect(declaration2.statement_line_items.map(&:statement)).to all(eq(from_statement2))
        end

        it "records information" do
          migrate

          expect(instance).to have_recorded_info([
            "Migrating declarations from #{from_statement_name} to #{to_statement_name} for 2 providers",
            "Migrating 1 declarations for #{npq_lead_provider.name}",
            "Migrating 0 declarations for #{npq_lead_provider2.name}",
          ])
        end

        context "when restrict_to_declaration_types contains a string" do
          let(:restrict_to_declaration_types) { %w[retained-1] }

          it "migrates only the declarations with the given declaration type" do
            migrate

            expect(declaration2.statement_line_items.map(&:statement)).to all(eq(to_statement2))
            expect(declaration.statement_line_items.map(&:statement)).to all(eq(from_statement))
          end
        end
      end
    end

    context "when to_statement_updates are provided" do
      let(:to_statement_updates) { { deadline_date: 5.days.from_now.to_date, payment_date: 2.days.from_now.to_date } }

      it "updates the to statements" do
        migrate

        expect(to_statement.reload).to have_attributes(to_statement_updates)
        expect(instance).to have_recorded_info([
          "Statement #{to_statement.name} for #{to_statement.npq_lead_provider.name} updated with #{to_statement_updates}",
        ])
      end
    end

    context "when dry_run is true" do
      let(:dry_run) { true }

      it "does not make any changes, but logs out as if it does" do
        expect { migrate }.not_to change { from_statement.reload.output_fee }

        expect(instance).to have_recorded_info([
          "~~~ DRY RUN ~~~",
          "Migrating declarations from #{from_statement_name} to #{to_statement_name} for 1 providers",
          "Migrating 0 declarations for #{npq_lead_provider.name}",
        ])
      end
    end

    describe "integrity checks" do
      context "when there is a mismatch between the number of statements" do
        let!(:mismatched_statement) { create(:npq_statement, cohort:, name: from_statement.name, output_fee: true) }

        it { expect { migrate }.to raise_error(described_class::StatementMismatchError, "There is a mismatch between to/from statements") }
      end

      context "when a to statement has a deadline date in the past" do
        before { to_statement.update!(deadline_date: 1.day.ago) }

        it { expect { migrate }.to raise_error(described_class::ToStatementDeadlineDateHasPastError, "To statements must be future dated") }
      end

      context "when attempting to migrate between statements on different cohorts" do
        let(:other_cohort) { Cohort.previous }

        before { from_statement.update!(cohort: other_cohort) }

        it { expect { migrate }.to raise_error(described_class::StatementMismatchError, "There is a mismatch between to/from statements") }
      end

      context "when attempting to migrate statements that are output_fee false" do
        before { from_statement.update!(output_fee: false) }

        it { expect { migrate }.to raise_error(described_class::StatementMismatchError, "There is a mismatch between to/from statements") }
      end

      context "when attempting to migrate ECF statements" do
        let(:from_statement) { create(:ecf_statement, name: "April 2023", cpd_lead_provider:, output_fee: true) }

        it { expect { migrate }.to raise_error(described_class::StatementMismatchError, "There is a mismatch between to/from statements") }
      end

      context "when there are no statements found" do
        let(:from_statement_name) { "Not found" }
        let(:to_statement_name) { "Not found" }

        it { expect { migrate }.to raise_error(described_class::StatementMismatchError, "No statements were found") }
      end
    end
  end
end
