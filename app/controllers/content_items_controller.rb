class ContentItemsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :parse_json_request, only: [:update]
  before_action :set_cors_headers, only: [:show]

  def show
    render json: { "hello": "show" }
  end

  def update
    result, item = ContentItem.create_or_replace(encoded_base_path, @request_data)

    response_body = {}
    case result
    when :created
      status = :created
    when :conflict
      status = :conflict
      response_body = { errors: item.errors.as_json }
    when false
      status = :unprocessable_entity
      response_body = { errors: item.errors.as_json }
    else
      status = :ok
    end

    render json: response_body, status:
  end

private

  def set_cors_headers
    # Allow any origin host to request the resource
    response.headers["Access-Control-Allow-Origin"] = "*"
  end
end
