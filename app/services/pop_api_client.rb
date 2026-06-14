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

  # Profiles (enrolled freelancers). API v2 has no enrollment-CRUD surface:
  # enrollment state is created through the OTP onboarding flow (see
  # #start_enrollment) and read back here.
  def list_profiles(page: 1, per_page: 25)
    get("/api/v2/partner/profiles", page: page, per_page: per_page)
  end

  def get_profile(worker_id)
    get("/api/v2/partner/profiles/#{encode_path(worker_id)}")
  end

  # Occupation codes
  def list_occupation_codes(page: 1, per_page: 100)
    get("/api/v2/partner/occupation_codes", page: page, per_page: per_page)
  end

  # Payouts
  # Create (and submit) a payout for an enrolled freelancer (API v2).
  #
  # Invoice-level fields:
  #   worker_id       — required, the partner's stable worker id
  #   idempotency_key — REQUIRED, customer-generated, unique per partner (≤200 chars).
  #                     Replaying a key returns the original payout (200) instead of duplicating.
  #   invoiced_on     — optional (POP derives from the last work end date if omitted)
  #   due_on          — optional, defaults to invoiced_on + 14 days
  #   buyer_reference — optional, defaults to partner account name
  #   order_reference — optional, partner's PO/reference number
  #   external_note   — optional, memo/note field on the invoice
  #
  # `work_lines` is an array of work lines (see Booker::BookingsController#pay for the
  # builder). Each work line: { occupation_code?, unit_price (øre, int), quantity?,
  # vat_rate? (0|0.25), duration { start_date, end_date, duration_hours? }, sub_lines? }.
  # Sub-lines (expense/mileage/diet/benefit/extra) nest under their work line.
  # All money is integer minor units (øre). Never floats.
  def create_payout(worker_id:, idempotency_key:, work_lines:, invoiced_on: nil, due_on: nil,
                    buyer_reference: nil, order_reference: nil, external_note: nil)
    body = {
      worker_id: worker_id,
      idempotency_key: idempotency_key,
      work_lines: work_lines
    }
    body[:invoiced_on] = invoiced_on if invoiced_on.present?
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

  # Onboarding (browser flow). POP emails the freelancer a 6-digit code (no
  # clickable link) and returns a co-branded handoff URL. Redirect the
  # freelancer's browser to response `url`; POP collects identity + bank on its
  # own hosted page, then redirects to return_url with
  # ?worker_id=…&status=approved|cancelled|expired.
  def start_enrollment(worker_id:, email:, return_url:, name: nil, locale: nil)
    post("/api/v2/partner/enroll_sessions", {
      worker_id: worker_id,
      email: email,
      return_url: return_url,
      name: name,
      locale: locale
    }.compact)
  end

  # Same OTP handoff, but lands the freelancer on the portal to change their
  # payout preference (salary↔company). Redirects back with status=updated|….
  def start_payout_method_session(worker_id:, email:, return_url:)
    post("/api/v2/partner/payout_method_sessions", {
      worker_id: worker_id,
      email: email,
      return_url: return_url
    })
  end

  # POP's app host — where the freelancer logs in to manage their profile.
  def app_url
    @credentials[:app_url].presence || ENV.fetch("POP_APP_URL") do
      # api.payoutpartner.com → app.payoutpartner.com (and the sandbox.* variant)
      base_url.sub("api.", "app.")
    end
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

  def encode_path(segment)
    ERB::Util.url_encode(segment.to_s)
  end

  def api_key
    @credentials[:api_key].presence || ENV["POP_API_KEY"] || raise_missing("POP_API_KEY")
  end

  def raise_missing(name)
    raise PopCredentialsMissing, "#{name} is not configured. Add it in Settings or set the environment variable."
  end

  def base_url
    @credentials[:base_url].presence || ENV.fetch("POP_BASE_URL", "https://sandbox.api.payoutpartner.com")
  end

end
