# frozen_string_literal: true

RSpec.describe StatusTags::AppropriateBodyParticipantStatusTag, type: :component do
  let(:component) { described_class.new participant_profile: ParticipantProfile.new }

  subject(:label) { render_inline component }

  context "The language file" do
    TrainingRecordState.record_states.each_key do |key|
      it "includes :#{key} as a language entry" do
        expect(I18n.t("status_tags.appropriate_body_participant_status").keys).to include key.to_sym
      end
    end
  end

  I18n.t("status_tags.appropriate_body_participant_status").each do |key, value|
    context "when :#{key} is the determined state" do
      before { allow(component).to receive(:record_state).and_return(key) }
      it { is_expected.to have_text value[:label] }
      it { is_expected.to have_text Array.wrap(value[:description]).join(" ") }
    end
  end
end
