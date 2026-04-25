module Hosts
  BOOKIFY = ENV.fetch("BOOKIFY_HOST", Rails.env.production? ? "bookify.app"        : "bookify.lvh.me:3000")
  POP     = ENV.fetch("POP_HOST",     Rails.env.production? ? "payoutpartner.com"  : "pop.lvh.me:3000")
end

# Domain routing is enforced in production and when DOMAIN_ROUTING=true in dev.
# In plain development (localhost) both constraints pass so all routes are reachable.
DOMAIN_ROUTING_ENABLED = Rails.env.production? || ENV["DOMAIN_ROUTING"] == "true"

class BookifyDomainConstraint
  def self.matches?(request)
    return true unless DOMAIN_ROUTING_ENABLED
    request.host.match?(/\Abookify\./i)
  end
end

class PopDomainConstraint
  def self.matches?(request)
    return true unless DOMAIN_ROUTING_ENABLED
    request.host.match?(/payoutpartner\.|pop\.lvh\.me/i)
  end
end
