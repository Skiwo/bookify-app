# Derive ActiveRecord encryption keys from SECRET_KEY_BASE so developers
# don't need to run `rails db:encryption:init` or manage separate key files.
# This is appropriate for a reference app — production apps should use
# Rails credentials or dedicated key management.
if ENV["SECRET_KEY_BASE"].present?
  key_base = ENV["SECRET_KEY_BASE"]

  ActiveRecord::Encryption.configure(
    primary_key: Digest::SHA256.hexdigest("active_record_encryption_primary_key:#{key_base}")[0, 32],
    deterministic_key: Digest::SHA256.hexdigest("active_record_encryption_deterministic_key:#{key_base}")[0, 32],
    key_derivation_salt: Digest::SHA256.hexdigest("active_record_encryption_key_derivation_salt:#{key_base}")
  )
end
