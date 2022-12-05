# frozen_string_literal: true

module Api
  module V1
    class ParticipantOutcomesController < Api::ApiController
      include ApiTokenAuthenticatable
      include ApiPagination

      def index
        participant_declarations_hash = serializer_class.new(paginate(query_scope)).serializable_hash
        render json: participant_declarations_hash.to_json
      end

      def show
        participant_declarations_hash = serializer_class.new(query_scope).serializable_hash
        render json: participant_declarations_hash.to_json
      end

    private

      def serializer_class
        ParticipantOutcomeSerializer
      end

      def query_scope
        ParticipantOutcomesQuery.new(
          cpd_lead_provider:,
          participant_external_id:,
        ).scope
      end

      def cpd_lead_provider
        current_user
      end

      def participant_external_id
        params[:id]
      end
    end
  end
end
