# frozen_string_literal: true

require "swagger_helper"

describe "API", type: :request, swagger_doc: "v3/api_spec.json", api_v3: true do
  let(:token) { LeadProviderApiToken.create_with_random_token!(cpd_lead_provider:) }
  let(:bearer_token) { "Bearer #{token}" }
  let(:Authorization) { bearer_token }

  path "/api/v3/participants/ecf" do
    get "<b>Note, this endpoint includes updated specifications.</b><br/>Retrieve multiple participants, replaces <code>/api/v3/participants</code>" do
      operationId :participants
      tags "ECF participants"
      security [bearerAuth: []]

      parameter name: :filter,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/ListFilter",
                },
                style: :deepObject,
                explode: true,
                required: false,
                description: "Refine ECF participants to return.",
                example: CGI.unescape({ filter: { cohort: 2022, updated_since: "2020-11-13T11:21:55Z" } }.to_param)

      parameter name: :page,
                in: :query,
                schema: {
                  "$ref": "#/components/schemas/Pagination",
                },
                style: :deepObject,
                explode: true,
                required: false,
                example: CGI.unescape({ page: { page: 1, per_page: 5 } }.to_param),
                description: "Pagination options to navigate through the list of ECF participants."

      response "200", "A list of ECF participants" do
        schema({ "$ref": "#/components/schemas/MultipleECFParticipantsResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/participants/ecf/{id}" do
    get "<b>Note, this endpoint includes updated specifications.</b><br/>Get a single ECF participant" do
      operationId :ecf_participant
      tags "ECF participants"
      security [bearerAuth: []]

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the ECF participant.",
                schema: {
                  type: "string",
                }

      response "200", "A single ECF participant" do
        let(:id) { mentor_profile.user.id }

        schema({ "$ref": "#/components/schemas/ECFParticipantResponse" })

        run_test!
      end

      response "401", "Unauthorized" do
        let(:id) { mentor_profile.user.id }
        let(:Authorization) { "Bearer invalid" }

        schema({ "$ref": "#/components/schemas/UnauthorisedResponse" })

        run_test!
      end

      response "404", "Not Found" do
        schema({ "$ref": "#/components/schemas/NotFoundResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/participants/ecf/{id}/defer" do
    put "<b>Note, this endpoint includes updated specifications.</b><br/>Notify that an ECF participant is taking a break from their course" do
      operationId "ecf_participant_defer"
      tags "ECF Participant"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the participant to defer",
                schema: {
                  type: "string",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFParticipantDeferRequest",
                }

      response "200", "The ECF participant being deferred" do
        let(:id) { mentor_profile.user.id }

        let(:params) do
          {
            data: {
              type: "participant",
              attributes: {
                reason: "career-break",
                course_identifier: "ecf-mentor",
              },
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ECFParticipantResponse" })

        # TODO: replace with actual implementation once implemented
        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json" => {
              examples: {
                success: {
                  value: JSON.parse({
                    data: {
                      id: "db3a7848-7308-4879-942a-c4a70ced400a",
                      type: "participant",
                      attributes: {
                        full_name: "Jane Smith",
                        teacher_reference_number: "1234567",
                        updated_at: "2021-05-31T02:22:32.000Z",
                        ecf_enrolments: {
                          training_record_id: "000a97ff-d2a9-4779-a397-9bfd9063072e",
                          email: "jane.smith@some-school.example.com",
                          mentor_id: "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
                          school_urn: "106286",
                          participant_type: "ect",
                          cohort: "2021",
                          training_status: "withdrawn",
                          participant_status: "withdrawn",
                          teacher_reference_number_validated: true,
                          eligible_for_funding: true,
                          pupil_premium_uplift: true,
                          sparsity_uplift: true,
                          schedule_identifier: "ecf-standard-january",
                          validation_status: "eligible_to_start",
                          delivery_partner_id: "cd3a12347-7308-4879-942a-c4a70ced400a",
                          withdrawal: nil,
                          deferral: {
                            reason: "other",
                            date: "2021-06-31T02:22:32.000Z",
                          },
                          created_at: "2022-11-09T16:07:38Z",
                        },
                      },
                    },
                  }.to_json, symbolize_names: true),
                },
              },
            },
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test!
      end
    end
  end

  path "/api/v3/participants/ecf/{id}/resume" do
    put "<b>Note, this endpoint includes updated specifications.</b><br/>Notify that an ECF participant is resuming their course" do
      operationId "ecf_participant_resume"
      tags "ECF Participant"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the participant to resume",
                schema: {
                  type: "string",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFParticipantResumeRequest",
                }

      response "200", "The ECF participant being resumed" do
        let!(:mentor_induction_record_deferred) { create(:induction_record, induction_programme:, participant_profile: deferred_mentor_profile, training_status: "deferred") }

        let(:participant) { deferred_mentor_profile }
        let(:id) { participant.participant_identity.external_identifier }

        let(:params) do
          {
            data: {
              type: "participant",
              attributes: {
                course_identifier: "ecf-mentor",
              },
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ECFParticipantResponse" })

        run_test!
      end
    end
  end

  path "/api/v3/participants/ecf/{id}/withdraw" do
    put "<b>Note, this endpoint includes updated specifications.</b><br/>Notify that an ECF participant has withdrawn from their course" do
      operationId :participant
      tags "ECF Participant"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the participant to withdraw"

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFParticipantWithdrawRequest",
                }

      response "200", "The ECF participant being withdrawn" do
        let(:id) { mentor_profile.user.id }
        let(:attributes) do
          {
            reason: "left-teaching-profession",
            course_identifier: "ecf-mentor",
          }
        end

        let(:params) do
          {
            "data": {
              "type": "participant",
              "attributes": attributes,
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ECFParticipantResponse" })

        # TODO: replace with actual implementation once implemented
        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            "application/json" => {
              examples: {
                success: {
                  value: JSON.parse({
                    data: {
                      id: "db3a7848-7308-4879-942a-c4a70ced400a",
                      type: "participant",
                      attributes: {
                        full_name: "Jane Smith",
                        teacher_reference_number: "1234567",
                        updated_at: "2021-05-31T02:22:32.000Z",
                        ecf_enrolments: {
                          training_record_id: "000a97ff-d2a9-4779-a397-9bfd9063072e",
                          email: "jane.smith@some-school.example.com",
                          mentor_id: "bb36d74a-68a7-47b6-86b6-1fd0d141c590",
                          school_urn: "106286",
                          participant_type: "ect",
                          cohort: "2021",
                          training_status: "withdrawn",
                          participant_status: "withdrawn",
                          teacher_reference_number_validated: true,
                          eligible_for_funding: true,
                          pupil_premium_uplift: true,
                          sparsity_uplift: true,
                          schedule_identifier: "ecf-standard-january",
                          validation_status: "eligible_to_start",
                          delivery_partner_id: "cd3a12347-7308-4879-942a-c4a70ced400a",
                          withdrawal: {
                            reason: "other",
                            date: "2021-06-31T02:22:32.000Z",
                          },
                          deferral: nil,
                          created_at: "2022-11-09T16:07:38Z",
                        },
                      },
                    },
                  }.to_json, symbolize_names: true),
                },
              },
            },
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
        end

        run_test!
      end
    end
  end

  path "/api/v3/participants/ecf/{id}/change-schedule" do
    put "<b>Note, this endpoint includes updated specifications.</b><br/>Notify that an ECF Participant is changing training schedule" do
      operationId "ecf_participant_change_schedule"
      tags "ECF Participant"
      security [bearerAuth: []]
      consumes "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                example: "28c461ee-ffc0-4e56-96bd-788579a0ed75",
                description: "The ID of the participant",
                schema: {
                  type: "string",
                }

      parameter name: :params,
                in: :body,
                style: :deepObject,
                required: true,
                schema: {
                  "$ref": "#/components/schemas/ECFParticipantChangeScheduleRequest",
                }

      response "200", "The ECF Participant changing schedule" do
        let(:participant) { mentor_profile }
        let(:id) { participant.user.id }
        let(:params) do
          {
            "data": {
              "type": "participant",
              "attributes": {
                schedule_identifier: "ecf-standard-september",
                course_identifier: "ecf-mentor",
              },
            },
          }
        end

        schema({ "$ref": "#/components/schemas/ECFParticipantResponse" })

        run_test!
      end
    end
  end
end