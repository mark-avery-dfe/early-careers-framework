# frozen_string_literal: true

module Support
  module CanRetrieveParticipantDetailsFromTheEcfParticipantsEndpoint
    extend RSpec::Matchers::DSL

    RSpec::Matchers.define :be_able_to_retrieve_the_details_of_the_participant_from_the_ecf_participants_endpoint do |participant_name, participant_type|
      match do |lead_provider_name|
        @error = nil
        @expected = nil
        @value = nil

        user = User.find_by(full_name: participant_name)
        raise "Could not find User for #{participant_name}" if user.nil?

        participant = user.participant_profiles.first
        raise "Could not find ParticipantProfile for #{participant_name}" if participant.nil?

        declarations_endpoint = APIs::ECFParticipantsEndpoint.new(tokens[lead_provider_name])
        attributes = declarations_endpoint.get_participant_details(participant)

        if attributes.nil?
          @error = :attributes
        else
          unless attributes["email"] == participant.user.email
            @error = :email
            @expected = participant.user.email
            @value = attributes["email"]
          end
          unless attributes["full_name"] == participant_name
            @error = :full_name
            @expected = participant_name
            @value = attributes["full_name"]
          end
          unless attributes["school_urn"] == participant.school.urn
            @error = :school_urn
            @expected = participant.school.urn
            @value = attributes["school_urn"]
          end
          unless attributes["participant_type"] == participant_type.downcase
            @error = :participant_type
            @expected = participant_type
            @value = attributes["participant_type"]
          end
        end

        @error.nil?
      end

      failure_message do |lead_provider_name|
        case @error
        when :attributes
          "'#{lead_provider_name}' Should have been able to retrieve the details of '#{participant_name}' from the ecf participants endpoint"
        else
          "'#{lead_provider_name}' Should have been able to retrieve [#{@expected}] but got [#{@value}] for [#{@error}] when #{lead_provider_name} calls the ecf participants endpoint"
        end
      end

      failure_message_when_negated do |lead_provider_name|
        case @error
        when :attributes
          "'#{lead_provider_name}' Should not have been able to retrieve the details of '#{participant_name}' from the ecf participants endpoint"
        else
          "'#{lead_provider_name}' Should not have been able to retrieve [#{@value}] for [#{@error}] when #{lead_provider_name} calls the ecf participants endpoint"
        end
      end

      description do
        "be able to retrieve the details of '#{participant_name}' from the ecf participants endpoint"
      end
    end
  end
end
