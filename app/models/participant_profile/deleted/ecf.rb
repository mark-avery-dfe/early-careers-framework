# frozen_string_literal: true

class ParticipantProfile < ApplicationRecord
  module Deleted
    class ECF < ParticipantProfile
    end
  end
end
