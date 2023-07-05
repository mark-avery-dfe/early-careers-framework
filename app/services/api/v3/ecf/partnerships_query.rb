# frozen_string_literal: true

module Api
  module V3
    module ECF
      class PartnershipsQuery
        include Concerns::FilterCohorts
        include Concerns::FilterUpdatedSince

        attr_reader :lead_provider, :params

        def initialize(lead_provider:, params:)
          @lead_provider = lead_provider
          @params = params
        end

        def partnerships
          scope = partnership_scope
          scope = scope.where(partnerships: { cohort:  cohorts })
          scope = scope.where("partnerships.updated_at > ?", updated_since) if updated_since_filter.present?
          scope = scope.where(partnerships: { delivery_partner: [delivery_partner_id_filter] }) if delivery_partner_id_filter.present?
          scope = scope.order("partnerships.created_at ASC") if params[:sort].blank?
          scope.distinct
        end

        def partnership
          partnership_scope.find(params[:id])
        end

      private

        def partnership_scope
          lead_provider.partnerships
            .includes(:cohort, :delivery_partner, school: :induction_coordinators)
            .where(relationship: false)
        end

        def delivery_partner_id_filter
          filter[:delivery_partner_id]&.split(",")
        end
      end
    end
  end
end
