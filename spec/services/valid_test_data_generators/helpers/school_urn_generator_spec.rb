# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::Helpers::SchoolUrnGenerator, type: :helper do
  describe ".next" do
    it "produces a new unassigned value" do
      expect(::School.pluck(:urn)).not_to include(described_class.next)
    end

    it "generates 10_000 unallocated TRNs in under a second" do
      benchmark = Benchmark.measure do
        10_000.times do
          described_class.next
        end
      end
      expect(benchmark.total).to be < 1
    end

    it "moves the new URN to unavailable" do
      number_of_urns_to_generate = 100
      before_count = described_class.send(:available).count
      number_of_urns_to_generate.times do
        described_class.next
      end
      after_count = described_class.send(:available).count
      expect(before_count - after_count).to eq number_of_urns_to_generate
    end
  end
end