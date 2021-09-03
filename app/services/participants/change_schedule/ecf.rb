# frozen_string_literal: true

module Participants
  module ChangeSchedule
    class ECF < ::Participants::Base
      include Participants::ECF
      include ValidateAndChange
    end
  end
end
