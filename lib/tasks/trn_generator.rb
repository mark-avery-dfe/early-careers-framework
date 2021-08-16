# frozen_string_literal: true

class TRNGenerator
  class << self
    def next
      available.pop || (raise "TRN available list exhausted")
    end

  private

    ALL_TRNS = ("0011111".."9999999").to_a.freeze unless defined?(ALL_TRNS)

    def available
      @available ||= (ALL_TRNS - taken).shuffle
    end

    def taken
      @taken ||= TeacherProfile.where.not(trn: nil).pluck(:trn)
    end
  end
end
