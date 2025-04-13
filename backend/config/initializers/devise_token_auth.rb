# frozen_string_literal: true

DeviseTokenAuth.setup do |config|
  # By default the authorization headers will change after each request. The
  # client is responsible for keeping track of the changing tokens. Change
  # this to false to prevent the Authorization header from changing after
  # each request.
  config.change_headers_on_each_request = false

  # By default, users will need to re-authenticate after 2 weeks. This setting
  # determines how long tokens will remain valid after they are issued.
  config.token_lifespan = 2.weeks

  # Limiting the token_cost to just 4 in testing will increase the performance of
  # your test suite dramatically. The possible cost value is within range from 4
  # to 31. It is recommended to not use a value more than 10 in other environments.
  config.token_cost = Rails.env.test? ? 4 : 10

  # Sets the max number of concurrent devices per user, which is 10 by default.
  # After this limit is reached, the oldest tokens will be removed.
  # config.max_number_of_devices = 10

  # Sometimes it's necessary to make several requests to the API at the same
  # time. In this case, each request in the batch will need to share the same
  # auth token. This setting determines how far apart the requests can be while
  # still using the same auth token.
  config.batch_request_buffer_throttle = 5.seconds

  # This route will be the prefix for all oauth2 redirect callbacks. For
  # example, using the default '/omniauth', the github oauth2 provider will
  # redirect successful authentications to '/omniauth/github/callback'
  # config.omniauth_prefix = "/omniauth"

  # By default sending current password is not needed for the password update.
  # Uncomment to enforce current_password param to be checked before all
  # attribute updates. Set it to :password if you want it to be checked only if
  # password is updated.
  # config.check_current_password_before_update = :attributes

  # By default we will use callbacks for single omniauth.
  # It depends on fields like email, provider and uid.
  # config.default_callbacks = true

  # Makes it possible to change the headers names
  # config.headers_names = {
  #   :'authorization' => 'Authorization',
  #   :'access-token' => 'access-token',
  #   :'client' => 'client',
  #   :'expiry' => 'expiry',
  #   :'uid' => 'uid',
  #   :'token-type' => 'token-type'
  # }

  # Makes it possible to use custom uid column
  # config.other_uid = "foo"

  # By default, only Bearer Token authentication is implemented out of the box.
  # If, however, you wish to integrate with legacy Devise authentication, you can
  # do so by enabling this flag. NOTE: This feature is highly experimental!
  config.enable_standard_devise_support = true

  # By default DeviseTokenAuth will not send confirmation email, even when including
  # devise confirmable module. If you want to use devise confirmable module and
  # send email, set it to true. (This is a setting for compatibility)
  # config.send_confirmation_email = true

  # By default the confirmation mail event is initiated after register. If you want
  # to trigger the event before registration use `add_confirmable_action :before_register_action`
  # config.add_confirmable_action :before_register_action

  # If using ActiveJob, specify the delivery method:
  # config.active_job_delivery_method = :deliver_later
  # Default is :deliver_now

  # Allow multiple simultaneous sessions per account per client. Acceptable values are `true` or `false`. Default is `false`.
  # Note: When enabled, the `token` field must be indexed in the database as it's used for lookups. Ensure this has been done.
  # config.enable_multiple_simultaneous_sessions = false

  # By default, `confirmation_success_url` is mandatory for email confirmations. Setting this option to `true`
  # allows the client to skip the `confirmation_success_url` parameter and doesn't send the user to the login page. Default is false.
  # config.skip_confirmation_url_check = false

  # The default value for the maximum number of login attempts is 10. After the user exceeds
  # this number of attempts, their account will be locked. Set this value to 0 to disable locking.
  # config.max_number_of_login_attempts = 10

  # The default interval for sending password reset emails is 1 minute. Set this value to 0 to disable the interval.
  # config.time_interval_for_password_reset_emails = 1.minute

  # By default, DeviseTokenAuth uses the standard Devise mailer to send emails. You can customize the mailer class by setting this option.
  # config.mailer = 'Devise::Mailer'
end
