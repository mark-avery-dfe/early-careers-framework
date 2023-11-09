# frozen_string_literal: true

module DeliveryPartners
  module Participants
    class TableRow < BaseComponent
      with_collection_parameter :induction_record

      delegate :user,
               :teacher_profile,
               :cohort,
               :role,
               to: :participant_profile

      delegate :full_name,
               to: :user

      delegate :training_status,
               :school,
               :participant_profile,
               to: :induction_record,
               allow_nil: true

      def initialize(induction_record:, training_record_states:)
        @induction_record = induction_record
        @training_record_states = training_record_states
      end

      def lead_provider_name
        induction_record&.induction_programme&.partnership&.lead_provider&.name
      end

      def email
        induction_record&.preferred_identity&.email || user.email
      end

    private

      attr_reader :induction_record, :training_record_states
    end
  end
end
