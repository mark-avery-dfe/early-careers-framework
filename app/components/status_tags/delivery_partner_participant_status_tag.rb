# frozen_string_literal: true

module StatusTags
  class DeliveryPartnerParticipantStatusTag < BaseComponent
    def initialize(participant_profile:, induction_record: nil, delivery_partner: nil)
      @participant_profile = participant_profile
      @induction_record = induction_record
      @delivery_partner = delivery_partner
    end

    def label
      t :label, scope: translation_scope
    end

    def id
      t :id, scope: translation_scope
    end

    def description
      Array.wrap(t(:description, scope: translation_scope, contact_us: render(MailToSupportComponent.new("contact us")))).map(&:html_safe)
    rescue I18n::MissingTranslationData
      []
    end

    def colour
      t :colour, scope: translation_scope
    end

  private

    attr_reader :participant_profile, :induction_record, :delivery_partner

    def translation_scope
      @translation_scope ||= "status_tags.delivery_partner_participant_status.#{record_state}"
    end

    def record_state
      @record_state ||= DetermineTrainingRecordState.call(participant_profile:, induction_record:, delivery_partner:).record_state
    end
  end
end
