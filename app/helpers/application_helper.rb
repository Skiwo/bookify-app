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

  def chat_sender_name(message, job)
    sender = message.sender
    if sender.id == job.shop.owner_id
      job.shop.name
    elsif sender.client? && job.client.user_id == sender.id
      job.client.org_name
    else
      sender.name.presence || sender.email.split("@").first
    end
  end

  def user_avatar(name_or_email, size: 40)
    initials = name_or_email.to_s.split(/[\s@]/).first(2).map { |w| w[0] }.join.upcase
    initials = "?" if initials.blank?
    content_tag :div, initials,
      class: "rounded-circle bg-secondary d-flex align-items-center justify-content-center text-white fw-bold",
      style: "width:#{size}px;height:#{size}px;font-size:#{size / 2.8}px;flex-shrink:0"
  end

  def shop_avatar(shop, size: 40)
    if shop.avatar.attached?
      image_tag shop.avatar,
        class: "rounded-circle",
        style: "width:#{size}px;height:#{size}px;object-fit:cover;flex-shrink:0"
    else
      initials = shop.name.split.first(2).map { |w| w[0] }.join.upcase
      content_tag :div, initials,
        class: "rounded-circle bg-primary d-flex align-items-center justify-content-center text-white fw-bold",
        style: "width:#{size}px;height:#{size}px;font-size:#{size / 2.8}px;flex-shrink:0"
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
    when Array then format_pop_error_detail_array(raw)
    when Hash
      raw.flat_map { |k, v| Array(v).map { |x| "#{k}: #{x}" } }.join("; ").presence
    end
  end

  def format_pop_error_detail_array(items)
    parts = items.filter_map do |item|
      case item
      when Hash
        field = item["field"].presence || item[:field].presence
        msg = item["message"].presence || item[:message].presence
        if field.present? && msg.present?
          "#{field}: #{msg}"
        elsif msg.present?
          msg
        elsif field.present?
          field
        end
      else
        item.to_s.presence
      end
    end
    parts.join("; ").presence
  end
end
