# frozen_string_literal: true

module Support
  module FindingParticipantDeclarationsInFinancePortal
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :be_able_to_find_the_training_declarations_for_the_participant_in_the_finance_portal do |participant_name, declarations|
      match do |finance_user|
        sign_in_as finance_user
        @error = nil

        user = User.find_by(full_name: participant_name)
        raise "Could not find User for #{participant_name}" if user.nil?

        participant = user.participant_profiles.first
        raise "Could not find ParticipantProfile for #{participant_name}" if participant.nil?

        portal = Pages::FinancePortal.new

        search = portal.view_participant_drilldown
        drilldown = search.find participant_name
        @text = page.find("main").text

        @error = :id unless drilldown.can_see_participant?(user.id)
        declarations.each do |declaration_type|
          @error = :declarations unless drilldown.can_see_declaration?(declaration_type, "ect-induction", "eligible")
        end

        sign_out

        if @error.nil?
          true
        else
          false
        end
      end

      failure_message do |_sit|
        "should have been able to retrieve the declarations #{declarations} for the training of '#{participant_name}' within:\n===\n#{@text}\n==="
      end

      failure_message_when_negated do |_sit|
        "should not have been able to retrieve the declarations #{declarations} for the training of '#{participant_name}' within:\n===\n#{@text}\n==="
      end

      description do
        if declarations.any?
          "be able to find the training declarations #{declarations} for '#{participant_name}' in the finance portal"
        else
          "be able to find no training declarations for '#{participant_name}' in the finance portal"
        end
      end
    end
  end
end
