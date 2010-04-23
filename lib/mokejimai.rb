require 'openssl'
require 'open-uri'

module Mokejimai
  
  CERT_PATH     = "http://downloads.webtopay.com/download/public.key"
  OLD_CERT_PATH = "http://downloads.webtopay.com/download/public_old.key"
  
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

  def get_public_key(cert_path)
     OpenSSL::X509::Certificate.new(open(cert_path).read).public_key
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

      send_error unless verify_cert(str, CERT_PATH) || verify_cert(str, OLD_CERT_PATH)
    end
  end
  
  def verify_cert(str, cert_path)
    public_key = get_public_key(cert_path)
    public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(params['_ss2']), str)  
  end
  
  def send_ok
    render :text => "ok"
  end
  
  def send_error
    render :text => "Error! Please contact the administrator.", :status => 500
  end
end
