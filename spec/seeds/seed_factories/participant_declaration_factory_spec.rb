# frozen_string_literal: true

require_relative "./shared_factory_examples"

RSpec.describe("seed_participant_declaration") do
  it_behaves_like("a seed factory") do
    let(:factory_name) { :seed_participant_declaration }
    let(:factory_class) { ParticipantDeclaration }
  end
end
