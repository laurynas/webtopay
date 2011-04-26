module WebToPay
  class Exception < ::Exception
    # Missing field.
    E_MISSING = 1

    # Invalid field value.
    E_INVALID = 2

    # Max length exceeded.
    E_MAXLEN = 3

    # Regexp for field value doesn't match.
    E_REGEXP = 4

    # Missing or invalid user given parameters.
    E_USER_PARAMS = 5

    # Logging errors
    E_LOG = 6

    # SMS answer errors
    E_SMS_ANSWER = 7

    attr_accessor :code, :field_name
  end
end
