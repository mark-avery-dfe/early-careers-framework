# frozen_string_literal: true

module Finance
  module NPQ
    class ParticipantAggregator < Finance::ParticipantAggregator
      def self.aggregation_types
        {
          started: {
            all: :unique_for_lead_provider_and_course_identifier,
            eligible_or_payable: :unique_for_lead_provider_and_course_identifier,
          },
        }
      end

    private

      attr_accessor :cpd_lead_provider, :recorder, :course_identifier, :statement

      def initialize(statement:, course_identifier:, recorder: ParticipantDeclaration::NPQ.where.not(state: %w[voided]))
        self.statement         = statement
        self.cpd_lead_provider = statement.cpd_lead_provider
        self.recorder          = recorder
        self.course_identifier = course_identifier
      end

      def aggregate(aggregation_type:, event_type:)
        scope = recorder.public_send(self.class.aggregation_types[event_type][aggregation_type], cpd_lead_provider, course_identifier)
        scope = scope.where(statement: statement)
        scope.count
      end
    end
  end
end
