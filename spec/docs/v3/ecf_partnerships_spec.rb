# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "API", type: :request, swagger_doc: "v3/api_spec.json", with_feature_flags: { api_v3: "active" } do
  let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider:) }
  let(:bearer_token) { "Bearer #{token}" }
  let(:Authorization) { bearer_token }

  let(:cpd_lead_provider) { create(:cpd_lead_provider, :with_lead_provider) }
  let(:lead_provider) { cpd_lead_provider.lead_provider }
  let!(:partnership) { create(:partnership, lead_provider:) }

  let(:params) {}

  path "/api/v3/partnerships/ecf" do
    get "Retrieve multiple ECF partnerships" do
      operationId :partnerships_ecf_get
      tags "ECF partnerships"
      security [bearerAuth: []]

      parameter name: :filter,
                schema: {
                  "$ref": "#/components/schemas/PartnershipsFilter",
                },
                in: :query,
                style: :deepObject,
                explode: true,
                required: false,
                description: "Refine partnerships to return.",
                example: "filter[cohort]=2021,2022"

      parameter name: :sort,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/PartnershipsSort",
                },
                style: :form,
                explode: false,
                required: false,
                description: "Sort partnerships being returned.",
                example: "sort=-updated_at"

      response "200", "A list of ECF partnerships" do
        schema({ "$ref": "#/components/schemas/MultipleECFPartnershipsResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/partnerships/ecf", api_v3: true do
    post "Create an ECF partnership with a school and delivery partner" do
      operationId :partnerships_ecf_post
      tags "ECF partnerships"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFPartnershipRequest",
                }

      response "200", "Create an ECF partnership" do
        schema({ "$ref": "#/components/schemas/ECFPartnershipResponse" })

        # TODO: replace with actual implementation once implemented
        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json" => {
              examples: {
                create_partnership: {
                  value: {
                    data: {
                      id: "cd3a12347-7308-4879-942a-c4a70ced400a",
                      type: "partnership",
                      attributes: {
                        cohort: 2021,
                        urn: "123456",
                        delivery_partner_name: "Delivery partner name",
                        delivery_partner_id: "cd3a12347-7308-4879-942a-c4a70ced400a",
                        school_id: "dd3a12347-7308-4879-942a-c4a70ced400a",
                        status: "active",
                        challenged_reason: nil,
                        challenged_at: "2021-05-31T02:22:32.000Z",
                        induction_tutor_name: "John Doe",
                        induction_tutor_email: "john.doe@example.com",
                        updated_at: "2021-05-31T02:22:32.000Z",
                        created_at: "2021-05-31T02:22:32.000Z",
                      },
                    },
                  },
                },
              },
            },
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "422", "Unprocessable entity" do
        schema({ "$ref": "#/components/schemas/ECFPartnershipRequestErrorResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/partnerships/ecf/{id}", api_v3: true do
    get "Get a single ECF partnership" do
      operationId :partnerships_ecf_get
      tags "ECF partnerships"
      security [bearerAuth: []]

      response "200", "A single partnership" do
        schema({ "$ref": "#/components/schemas/ECFPartnershipResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "404", "Not Found" do
        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end

    put "Update a partnership’s delivery partner in an existing partnership in a cohort" do
      operationId :partnerships_ecf_put
      tags "ECF partnerships"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the partnership to update",
                schema: {
                  type: "string",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFPartnershipUpdateRequest",
                }

      response "200", "Update an ECF partnership" do
        schema({ "$ref": "#/components/schemas/ECFPartnershipResponse" })

        # TODO: replace with actual implementation once implemented
        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json" => {
              examples: {
                update_partnership: {
                  value: {
                    data: {
                      id: "cd3a12347-7308-4879-942a-c4a70ced400a",
                      type: "partnership",
                      attributes: {
                        cohort: 2021,
                        urn: "123456",
                        delivery_partner_name: "Delivery partner name",
                        delivery_partner_id: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                        school_id: "dd3a12347-7308-4879-942a-c4a70ced400a",
                        status: "active",
                        challenged_reason: nil,
                        challenged_at: "2021-05-31T02:22:32.000Z",
                        induction_tutor_name: "John Doe",
                        induction_tutor_email: "john.doe@example.com",
                        updated_at: "2021-05-31T02:22:32.000Z",
                        created_at: "2021-05-31T02:22:32.000Z",
                      },
                    },
                  },
                },
              },
            },
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "422", "Unprocessable entity" do
        schema({ "$ref": "#/components/schemas/ECFPartnershipRequestErrorResponse" })

        run_test!
      end
    end
  end
end
