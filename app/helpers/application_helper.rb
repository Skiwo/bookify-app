module ApplicationHelper
  def nav_active?(controller_prefix)
    controller.controller_path.start_with?(controller_prefix) ? "active" : ""
  end

  def pop_environment_banner(pop_base_url)
    return nil unless pop_base_url.present?
    if pop_base_url.include?("sandbox") || pop_base_url.include?("localhost")
      { name: "Sandbox", color: "warning", text_class: "text-dark", icon: "bi-cone-striped" }
    else
      { name: "Production", color: "success", text_class: "text-white", icon: "bi-lightning-charge-fill" }
    end
  end

  def format_nok(ore_amount)
    return "—" unless ore_amount
    nok = ore_amount / 100.0
    "kr #{"%.2f" % nok}"
  end

  def format_nok_value(nok_value)
    return "—" unless nok_value
    "kr #{"%.2f" % nok_value}"
  end

  # Format a POP API error for display, including the error code when available.
  # Example: "[worker_not_found] Worker not found"
  # Appends nested details/errors from the JSON body when POP returns them (422 validation).
  def format_pop_error(error)
    return error.to_s unless error.respond_to?(:code)
    parts = []
    parts << "[#{error.code}]" if error.code.present?
    parts << error.message if error.message.present?
    detail = pop_api_error_detail_string(error)
    parts << "(#{detail})" if detail.present?
    parts.join(" ").presence || "Unknown error"
  end

  private

  def pop_api_error_detail_string(error)
    return unless error.respond_to?(:body)
    body = error.body
    return unless body.is_a?(Hash)

    err = body["error"]
    err = body if err.nil? || !err.is_a?(Hash)
    raw = err["details"] || err["errors"] || body["errors"]
    case raw
    when String then raw.strip.presence
    when Array then raw.map(&:to_s).reject(&:blank?).join("; ").presence
    when Hash
      raw.flat_map { |k, v| Array(v).map { |x| "#{k}: #{x}" } }.join("; ").presence
    end
  end
end
