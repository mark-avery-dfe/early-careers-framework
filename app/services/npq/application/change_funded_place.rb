# frozen_string_literal: true

module NPQ
  module Application
    class ChangeFundedPlace
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :npq_application
      attribute :funded_place

      validates :npq_application, presence: { message: I18n.t("npq_application.missing_npq_application") }
      validate :accepted_application
      validate :eligible_for_funding
      validate :eligible_for_removing_funding_place
      # validate :funding_cap_available

      def call
        return self unless valid?

        Rails.logger.debug "*" * 100
        Rails.logger.debug npq_application.funded_place
        Rails.logger.debug funded_place

        ApplicationRecord.transaction do
          if FeatureFlag.active?("npq_capping")
            npq_application.update!(funded_place:)
          end
        end

        npq_application
      end

    private

      def accepted_application
        return if npq_application.accepted?

        errors.add(:npq_application, I18n.t("npq_application.cannot_change_funded_status_from_non_accepted"))
      end

      def eligible_for_funding
        return if npq_application.eligible_for_funding?

        errors.add(:npq_application, I18n.t("npq_application.cannot_change_funded_status_non_eligible"))
      end

      def eligible_for_removing_funding_place
        return if npq_application.funded_place?

        declarations_states = npq_application
                                .profile
                                .participant_declarations
                                .map(&:declaration_states).flatten

        errors.add(:npq_application, I18n.t("npq_application.cannot_remove_funding_voided_declaration")) if declarations_states.any?(&:voided?)
        errors.add(:npq_application, I18n.t("npq_application.cannot_remove_funding_awaiting_clawback_declaration")) if declarations_states.any?(&:awaiting_clawback!)
        errors.add(:npq_application, I18n.t("npq_application.cannot_remove_funding_clawed_back_declaration")) if declarations_states.any?(&:clawed_back!)
      end
    end
  end
end
