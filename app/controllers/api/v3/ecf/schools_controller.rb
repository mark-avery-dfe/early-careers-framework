# frozen_string_literal: true

module Api
  module V3
    module ECF
      class SchoolsController < Api::ApiController
        include ApiTokenAuthenticatable
        include ApiPagination
        include ApiFilter
        include ApiOrderable

        # Retrieve multiple ECF schools scoped to cohort
        #
        # GET /api/v3/schools/ecf?filter[cohort]=2021&sort=-updated_at
        #
        def index
          render json: serializer_class.new(paginate(ecf_schools)).serializable_hash.to_json
        end

        # Retrieve a single ECF school scoped to cohort
        #
        # GET /api/v3/schools/ecf/:school_id?filter[cohort]=2021
        #
        def show
          render json: serializer_class.new(ecf_school).serializable_hash.to_json
        end

      private

        def ecf_schools
          @ecf_schools ||= SchoolCohort.includes(:cohort, school: :partnerships)
                             .where(cohort: { start_year: params[:filter][:cohort] })
                             .order(sort_params(params))
        end

        def ecf_school
          ecf_schools.find_by!(school_id: params[:id])
        end

        def access_scope
          LeadProviderApiToken.joins(cpd_lead_provider: [:lead_provider])
        end

        def serializer_class
          Api::V3::ECF::SchoolCohortSerializer
        end

        def required_filter_params
          [:cohort]
        end
      end
    end
  end
end