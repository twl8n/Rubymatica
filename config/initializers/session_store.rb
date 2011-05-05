# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_am_ruby_session',
  :secret      => 'dc82a8974bb3c2a2b9f5c91d3eac67802f515ab202c4297d97807679f725d0dfc4757436e45ff372e46c748b84f0a9af8eba59c6d8619bc690e07eee0ffe2ead'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
