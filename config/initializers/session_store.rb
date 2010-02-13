# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_zomgblog_session',
  :secret => 'ae6e92cd512c900cb292f93b3ca30643939d8bb5403f84e9311a8f4b9619f75a0419eef9b88e642e4fa1f71df28e0c05a6e5edd632cdbbe42caed0cc46763c1f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
