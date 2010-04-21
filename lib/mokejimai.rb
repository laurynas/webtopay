require 'openssl'
require 'open-uri'

module Mokejimai
  
  #CERT_STRING = "MIIECTCCA3KgAwIBAgIBADANBgkqhkiG9w0BAQUFADCBujELMAkGA1UEBhMCTFQxEDAOBgNVBAgTB1ZpbG5pdXMxEDAOBgNVBAcTB1ZpbG5pdXMxHjAcBgNVBAoTFVVBQiBFVlAgSW50ZXJuYXRpb25hbDEtMCsGA1UECxMkaHR0cDovL3d3dy5tb2tlamltYWkubHQvYmFua2xpbmsucGhwMRkwFwYDVQQDExB3d3cubW9rZWppbWFpLmx0MR0wGwYJKoZIhvcNAQkBFg5wYWdhbGJhQGV2cC5sdDAeFw0wOTA3MjQxMjMxMTVaFw0xNzEwMTAxMjMxMTVaMIG6MQswCQYDVQQGEwJMVDEQMA4GA1UECBMHVmlsbml1czEQMA4GA1UEBxMHVmlsbml1czEeMBwGA1UEChMVVUFCIEVWUCBJbnRlcm5hdGlvbmFsMS0wKwYDVQQLEyRodHRwOi8vd3d3Lm1va2VqaW1haS5sdC9iYW5rbGluay5waHAxGTAXBgNVBAMTEHd3dy5tb2tlamltYWkubHQxHTAbBgkqhkiG9w0BCQEWDnBhZ2FsYmFAZXZwLmx0MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeT23V/kNtf/hrNae/ZsLfRZd8E+os6HZ9CbgvB+X659kBDBq5vjMDCVkY6sicn1fcFfuotEcbhKSKDrDAQ+DmCMm96C7A4gqCC5OqmINauxYDdbie7V9GJWnbRXDs/5Mu722f5TuOUG3HhN/vTg8uCxIrGIYv9idhvTbDyieVCwIDAQABo4IBGzCCARcwHQYDVR0OBBYEFI1VhRQeacLkR4OekokkQq0dFDAHMIHnBgNVHSMEgd8wgdyAFI1VhRQeacLkR4OekokkQq0dFDAHoYHApIG9MIG6MQswCQYDVQQGEwJMVDEQMA4GA1UECBMHVmlsbml1czEQMA4GA1UEBxMHVmlsbml1czEeMBwGA1UEChMVVUFCIEVWUCBJbnRlcm5hdGlvbmFsMS0wKwYDVQQLEyRodHRwOi8vd3d3Lm1va2VqaW1haS5sdC9iYW5rbGluay5waHAxGTAXBgNVBAMTEHd3dy5tb2tlamltYWkubHQxHTAbBgkqhkiG9w0BCQEWDnBhZ2FsYmFAZXZwLmx0ggEAMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAwIZwRb2E//fmXrcO2hnUYaG9spg1xCvRVrlfasLRURzcwwyUpJian7+HTdTNhrMa0rHpNlS0iC8hx1Xfltql//lc7EoyyIRXrom4mijCFUHmAMvR5AmnBvEYAUYkLnd/QFm5/utEm5JsVM8LidCtXUppCehy1bqp/uwtD4b4F3c="
  CERT_PATH = "http://downloads.webtopay.com/download/public.key"
  
  module ClassMethods
    def webtopay(*actions)
      before_filter :check
      write_inheritable_array(:actions, actions)
    end
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
  end
  
  protected
  
  def webtopay_required?
    (self.class.read_inheritable_attribute(:actions) || []).include?(action_name.to_sym)
  end

  def get_public_key
     OpenSSL::X509::Certificate.new(open(CERT_PATH).read).public_key
  end

  def check
    if webtopay_required?
      if params['_ss2'].nil?
        send_error
        return false
      end
    
      # this is very important for requirement of strict params sorting
      str = ""
      request.query_string.split(/&/).each do |item|
          key, val = item.split(/\=/)
          if !['_ss2', 'action', 'controller'].include?(key)
            val ||= ""
            str << CGI.unescape(val) + '|'
          end
      end

      #public_key = OpenSSL::X509::Certificate.new(Base64.decode64(CERT_STRING)).public_key
      public_key = get_public_key
      send_error if !public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(params['_ss2']), str)
    end
  end
  
  def send_ok
    render :text => "ok"
  end
  
  def send_error
    render :text => "Error! Please contact the administrator.", :status => 500
  end
end
