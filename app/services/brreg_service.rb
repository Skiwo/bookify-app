class BrregService
  BASE_URL = "https://data.brreg.no/enhetsregisteret/api/enheter"

  Result = Struct.new(:success, :name, :address, :error, keyword_init: true) do
    def success? = success
  end

  def self.lookup(org_number)
    response = connection.get(org_number.to_s)

    case response.status
    when 200
      data = response.body
      if inactive?(data)
        Result.new(success: false, error: "Organisation is not active (#{inactive_reason(data)})")
      else
        Result.new(success: true, name: data["navn"], address: format_address(data))
      end
    when 404
      Result.new(success: false, error: "Organisasjonsnummer #{org_number} not found in BRREG")
    else
      Result.new(success: false, error: "BRREG returned unexpected status #{response.status}")
    end
  rescue Faraday::Error => e
    Result.new(success: false, error: "BRREG unreachable: #{e.message}")
  end

  private

  def self.connection
    Faraday.new(url: BASE_URL) do |f|
      f.response :json
      f.options.timeout = 5
      f.options.open_timeout = 3
    end
  end

  def self.inactive?(data)
    data["slettedato"].present? ||
      data["konkurs"] == true ||
      data["underAvvikling"] == true ||
      data["underTvangsavviklingEllerTvangsopplosning"] == true
  end

  def self.inactive_reason(data)
    return "deleted" if data["slettedato"].present?
    return "bankrupt" if data["konkurs"]
    return "winding up" if data["underAvvikling"]
    "forced dissolution"
  end

  def self.format_address(data)
    addr = data["forretningsadresse"] || data["postadresse"]
    return nil unless addr
    [
      Array(addr["adresse"]).join(", "),
      "#{addr["postnummer"]} #{addr["poststed"]}".strip,
      ("Norge" if addr["landkode"] == "NO")
    ].reject(&:blank?).join(", ")
  end
end
