# frozen_string_literal: true

require "has_recordable_information"

module Oneoffs::NPQ
  class MigrateDeclarationsBetweenStatements
    class StatementMismatchError < RuntimeError; end
    class ToStatementDeadlineDateHasPastError < RuntimeError; end

    include HasRecordableInformation

    def initialize(cohort:, from_statement_name:, to_statement_name:, from_statement_output_fee: false, to_statement_updates: {}, restrict_to_lead_providers: nil, restrict_to_declaration_types: nil)
      @cohort = cohort
      @from_statement_name = from_statement_name
      @to_statement_name = to_statement_name
      @from_statement_output_fee = from_statement_output_fee
      @to_statement_updates = to_statement_updates
      @restrict_to_lead_providers = restrict_to_lead_providers
      @restrict_to_declaration_types = restrict_to_declaration_types
    end

    def migrate(dry_run: true)
      reset_recorded_info
      ensure_to_statements_are_future_dated!
      ensure_statements_align!
      record_summary_info(dry_run)

      ActiveRecord::Base.transaction do
        migrate_declarations_between_statements!
        update_to_statement_attributes!

        raise ActiveRecord::Rollback if dry_run
      end

      recorded_info
    end

  private

    attr_reader :cohort, :from_statement_name, :to_statement_name, :to_statement_updates, :restrict_to_lead_providers, :restrict_to_declaration_types, :from_statement_output_fee

    def update_to_statement_attributes!
      return if to_statement_updates.blank?

      to_statements_by_provider.each_value do |statement|
        statement.update!(to_statement_updates)
        record_info("Statement #{statement.name} for #{statement.npq_lead_provider.name} updated with #{to_statement_updates}")
      end
    end

    def migrate_declarations_between_statements!
      each_statements_by_provider do |provider, from_statement, to_statement|
        migrate_line_items!(provider, from_statement, to_statement)
        from_statement.update!(output_fee: from_statement_output_fee) if from_statement.output_fee != from_statement_output_fee
      end
    end

    def migrate_line_items!(provider, from_statement, to_statement)
      statement_line_items = from_statement.statement_line_items

      if restrict_to_declaration_types
        statement_line_items = statement_line_items
          .includes(:participant_declaration)
          .where(participant_declaration: { declaration_type: restrict_to_declaration_types })
      end

      record_line_items_info(provider, statement_line_items)

      statement_line_items.update!(statement_id: to_statement.id)
    end

    def each_statements_by_provider
      from_statements_by_provider.each do |provider, from_statement|
        to_statement = to_statements_by_provider[provider]
        yield(provider, from_statement, to_statement)
      end
    end

    def record_summary_info(dry_run)
      record_info("~~~ DRY RUN ~~~") if dry_run
      record_info("Migrating declarations from #{from_statement_name} to #{to_statement_name} for #{provider_count} providers")
    end

    def record_line_items_info(provider, statement_line_items)
      record_info("Migrating #{statement_line_items.size} declarations for #{provider.name}")
    end

    def ensure_to_statements_are_future_dated!
      raise ToStatementDeadlineDateHasPastError, "To statements must be future dated" if to_statements_by_provider.values.any? { |statement| statement.deadline_date.past? }
    end

    def ensure_statements_align!
      statements_mismatch = from_statements_by_provider.keys.sort != to_statements_by_provider.keys.sort
      statements_empty = from_statements_by_provider.empty? && to_statements_by_provider.empty?

      raise StatementMismatchError, "There is a mismatch between to/from statements" if statements_mismatch
      raise StatementMismatchError, "No statements were found" if statements_empty
    end

    def provider_count
      from_statements_by_provider.count
    end

    def from_statements_by_provider
      @from_statements_by_provider ||= statements_by_provider(from_statement_name)
    end

    def to_statements_by_provider
      @to_statements_by_provider ||= statements_by_provider(to_statement_name)
    end

    def statements_by_provider(statement_name)
      npq_lead_provider = restrict_to_lead_providers || NPQLeadProvider.all

      Finance::Statement::NPQ
        .includes(:cohort, :participant_declarations, cpd_lead_provider: :npq_lead_provider)
        .where(cohort:, name: statement_name, cpd_lead_provider: { npq_lead_provider: })
        .output
        .group_by(&:npq_lead_provider)
        .transform_values(&:first)
    end
  end
end
