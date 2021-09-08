# frozen_string_literal: true

module Api
  class ApiController < ActionController::API
    include ActionController::MimeResponds
    before_action :remove_charset
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActionController::ParameterMissing, with: :missing_parameter_response
    rescue_from ActionController::BadRequest, with: :bad_request_response
    rescue_from ActiveRecord::StatementInvalid, with: :bad_request_response
    rescue_from ArgumentError, with: :bad_request_response
    rescue_from ActiveRecord::RecordNotUnique, with: :conflict_response

  private

    def not_found
      head :not_found
    end

    def remove_charset
      ActionDispatch::Response.default_charset = nil
    end

    def missing_parameter_response(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: "Bad or missing parameters", params: exception.param).call }, status: :unprocessable_entity
    end

    def bad_request_response(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: "Bad request", params: exception.message).call }, status: :bad_request
    end

    def conflict_response(exception)
      render json: { errors: Api::ParamErrorFactory.new(error: "Conflict", params: exception.message).call }, status: :conflict
    end
  end
end
