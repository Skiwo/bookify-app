class PopApiClient
  attr_reader :api_calls

  PopCredentialsMissing = Class.new(StandardError)
  ApiError = Struct.new(:status, :code, :message, :body, keyword_init: true)
  ApiResult = Struct.new(:success?, :data, :error, :status, keyword_init: true)

  def initialize(credentials = {})
    @credentials = credentials
    @api_calls = []
  end

  def self.for_user(user)
    new(user.pop_credentials)
  end

  # Enrollments
  def list_enrollments(page: 1, per_page: 25)
    get("/api/v2/partner/enrollments", page: page, per_page: per_page)
  end

  def get_enrollment(enrollment_id)
    get("/api/v2/partner/enrollments/#{encode_path(enrollment_id)}")
  end

  def delete_enrollment(enrollment_id)
    delete("/api/v2/partner/enrollments/#{encode_path(enrollment_id)}")
  end

  def deactivate_enrollment(enrollment_id)
    post("/api/v2/partner/enrollments/#{encode_path(enrollment_id)}/deactivate", {})
  end

  def reactivate_enrollment(enrollment_id)
    post("/api/v2/partner/enrollments/#{encode_path(enrollment_id)}/reactivate", {})
  end

  # Profiles
  def get_profile(worker_id)
    get("/api/v2/partner/profiles/#{encode_path(worker_id)}")
  end

  # Occupation codes
  def list_occupation_codes(page: 1, per_page: 100)
    get("/api/v2/partner/occupation_codes", page: page, per_page: per_page)
  end

  # Payouts
  # Create a payout (invoice) for a freelancer.
  #
  # Invoice-level fields:
  #   worker_id       — required, the partner_worker_id for the freelancer
  #   occupation_code — optional, falls back to partner default on POP
  #   invoiced_on     — optional, defaults to today
  #   due_on          — optional, defaults to invoiced_on + 14 days
  #   buyer_reference — optional, defaults to partner account name
  #   order_reference — optional, partner's PO/reference number
  #   external_note   — optional, memo/note field on the invoice
  #   idempotency_key — optional, auto-generated from invoice contents if omitted
  #
  # Each line in `lines` accepts:
  #   description     — required, work description
  #   rate            — required, hourly/unit rate in NOK (not øre)
  #   quantity        — optional, defaults to 1
  #   occupation_code — optional, overrides invoice-level code for this line
  #   work_started_at — optional, ISO8601 timestamp
  #   work_ended_at   — optional, ISO8601 timestamp
  #   work_hours      — optional, used to calculate work_ended_at if not provided
  #   external_id     — optional, partner's line item reference
  def create_payout(worker_id:, lines:, occupation_code: nil, invoiced_on: nil, due_on: nil,
                    buyer_reference: nil, order_reference: nil, external_note: nil, idempotency_key: nil)
    # Omit nil and blank strings — Hash#compact alone still sends "" which POP may reject as "blank".
    cleaned_lines = lines.map { |line| omit_blank_values(line) }
    body = {
      worker_id: worker_id,
      invoiced_on: invoiced_on.presence || Date.current.iso8601,
      idempotency_key: idempotency_key,
      lines: cleaned_lines
    }
    body[:occupation_code] = occupation_code if occupation_code.present?
    body[:due_on] = due_on if due_on.present?
    body[:buyer_reference] = buyer_reference if buyer_reference.present?
    body[:order_reference] = order_reference if order_reference.present?
    body[:external_note] = external_note if external_note.present?
    post("/api/v2/partner/payouts", body)
  end

  def get_payout(payout_id)
    get("/api/v2/partner/payouts/#{encode_path(payout_id)}")
  end

  def list_payouts(page: 1, per_page: 25, status: nil)
    params = { page: page, per_page: per_page }
    params[:status] = status if status.present?
    get("/api/v2/partner/payouts", params)
  end

  # Browser flow JWT generation
  def connect_url(worker_id:, callback_url:)
    jwt = generate_jwt(
      partner_worker_id: worker_id,
      callback_url: callback_url
    )
    "#{app_url}/freelancer/connect?token=#{jwt}"
  end

  private

  def omit_blank_values(hash)
    hash.each_with_object({}) do |(key, value), acc|
      next if value.nil?
      next if value.is_a?(String) && value.strip.empty?

      acc[key] = value
    end
  end

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.options.open_timeout = 10
      f.options.timeout = 30
    end
  end

  def get(path, params = {})
    response = connection.get(path) do |req|
      req.headers.merge!(auth_headers)
      req.params = params
    end
    record_call("GET", path, params, nil, response)
    build_result(response)
  rescue Faraday::Error => e
    record_call("GET", path, params, nil, nil, e)
    build_error_result(e)
  end

  def post(path, body)
    response = connection.post(path) do |req|
      req.headers.merge!(auth_headers)
      req.body = body
    end
    record_call("POST", path, {}, body, response)
    build_result(response)
  rescue Faraday::Error => e
    record_call("POST", path, {}, body, nil, e)
    build_error_result(e)
  end

  def delete(path)
    response = connection.delete(path) do |req|
      req.headers.merge!(auth_headers)
    end
    record_call("DELETE", path, {}, nil, response)
    build_result(response)
  rescue Faraday::Error => e
    record_call("DELETE", path, {}, nil, nil, e)
    build_error_result(e)
  end

  def build_result(response)
    if response.status.between?(200, 299)
      ApiResult.new(success?: true, data: response.body, status: response.status)
    else
      body = response.body.is_a?(Hash) ? response.body : {}
      error = ApiError.new(
        status: response.status,
        code: body.dig("error", "code"),
        message: body.dig("error", "message") || "Request failed",
        body: response.body
      )
      ApiResult.new(success?: false, data: nil, error: error, status: response.status)
    end
  end

  def build_error_result(exception)
    error = ApiError.new(
      status: 0,
      code: "connection_error",
      message: exception.message,
      body: nil
    )
    ApiResult.new(success?: false, data: nil, error: error, status: 0)
  end

  def record_call(method, path, params, body, response, exception = nil)
    @api_calls << {
      method: method,
      path: path,
      params: params.presence,
      headers: masked_auth_headers,
      request_body: body,
      status: response&.status || 0,
      response_body: response&.body,
      error: exception&.message,
      timestamp: Time.current.iso8601
    }.compact
  end

  def auth_headers
    {
      "Authorization" => "Bearer #{api_key}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def masked_auth_headers
    key = api_key
    masked = key.length > 8 ? "***#{key[-4..]}" : "***"
    {
      "Authorization" => "Bearer #{masked}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def generate_jwt(payload)
    now = Time.current.to_i
    full_payload = payload.merge(
      partner_id: partner_id,
      iat: now,
      exp: now + 1800,
      jti: SecureRandom.uuid
    )
    JWT.encode(full_payload, hmac_secret, "HS256")
  end

  def encode_path(segment)
    ERB::Util.url_encode(segment.to_s)
  end

  def api_key
    @credentials[:api_key].presence || ENV["POP_API_KEY"] || raise_missing("POP_API_KEY")
  end

  def hmac_secret
    @credentials[:hmac_secret].presence || ENV["POP_HMAC_SECRET"] || raise_missing("POP_HMAC_SECRET")
  end

  def partner_id
    @credentials[:partner_id].presence || ENV["POP_PARTNER_ID"] || raise_missing("POP_PARTNER_ID")
  end

  def raise_missing(name)
    raise PopCredentialsMissing, "#{name} is not configured. Add it in Settings or set the environment variable."
  end

  def base_url
    @credentials[:base_url].presence || ENV.fetch("POP_BASE_URL", "https://sandbox.core.payoutpartner.com")
  end

  def app_url
    @credentials[:app_url].presence || ENV.fetch("POP_APP_URL") do
      base_url.sub("core.", "app.")
    end
  end

end
