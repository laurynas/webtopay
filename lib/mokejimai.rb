require 'openssl'

module Mokejimai
  
  CERT_STRING = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlETHpDQ0FwaWdBd0lCQWdJQkFUQU5CZ2txaGtpRzl3MEJBUVVGQURCdE1Rc3dDUVlEVlFRR0V3Sk1WREVRDQpNQTRHQTFVRUJ4TUhWbWxzYm1sMWN6RWZNQjBHQTFVRUNoTVdSVlpRSUVsdWRHVnlibUYwYVc5dVlXd3NJRlZCDQpRakVQTUEwR0ExVUVBeE1HWlhad0xteDBNUm93R0FZSktvWklodmNOQVFrQkZndHBibVp2UUdWMmNDNXNkREFlDQpGdzB3T0RBM01ESXhNVFExTURWYUZ3MHdPVEEzTURJeE1UUTFNRFZhTUdVeEN6QUpCZ05WQkFZVEFreFVNUjh3DQpIUVlEVlFRS0V4WkZWbEFnU1c1MFpYSnVZWFJwYjI1aGJDd2dWVUZDTVJrd0Z3WURWUVFERXhCM2QzY3VkMlZpDQpkRzl3WVhrdVkyOXRNUm93R0FZSktvWklodmNOQVFrQkZndHBibVp2UUdWMmNDNXNkRENCbnpBTkJna3Foa2lHDQo5dzBCQVFFRkFBT0JqUUF3Z1lrQ2dZRUF4bEh5T3Z0THgxOVZDUCtaa1hkc0dYS3BGZzVnalc4V1d4UFh5MVlJDQpBTkxaZlhOYkpzRWRzbEUxeDBUdkRMVUU4WUxTaXRVaE9OSDRmVDBCdWVDM3ArRUlkZFdSK01VQ0tEcks0UzFDDQp2VWxta3JoMFU3dkg1OWZLbDc1Q09CR1ArUG9wZjBoamEvNnFpZUpWaHBqQ1VGa0ZCRHpwVjNjMzQyQm9aYWd5DQphVHNDQXdFQUFhT0I1akNCNHpBSkJnTlZIUk1FQWpBQU1Dd0dDV0NHU0FHRytFSUJEUVFmRmgxUGNHVnVVMU5NDQpJRWRsYm1WeVlYUmxaQ0JEWlhKMGFXWnBZMkYwWlRBZEJnTlZIUTRFRmdRVXlUWnBWY3JiVEllVjI2SkpoMkhZDQoxZlp4WUVBd2dZZ0dBMVVkSXdTQmdEQitvWEdrYnpCdE1Rc3dDUVlEVlFRR0V3Sk1WREVRTUE0R0ExVUVCeE1IDQpWbWxzYm1sMWN6RWZNQjBHQTFVRUNoTVdSVlpRSUVsdWRHVnlibUYwYVc5dVlXd3NJRlZCUWpFUE1BMEdBMVVFDQpBeE1HWlhad0xteDBNUm93R0FZSktvWklodmNOQVFrQkZndHBibVp2UUdWMmNDNXNkSUlKQU1nODM2c2cwWVltDQpNQTBHQ1NxR1NJYjNEUUVCQlFVQUE0R0JBRGY1MVlzOWVrQVlNdFZnS3NFMlFaWjhueDZUWnRTejFNN1ZYQ282DQp2U2hLWkI0TlRIM1AyRDNVaG42Y0hLZXMwVGJTWlZWQ2hsRE1ON2MwVjAzQUpXdzJrQlhram5iQTRLeDJxeUlJDQo4R1dlVW1CdmdHYVR4cmZnZXh2TXExN0NEVmVrbUE5ekJoK09FMVZ3THdrVUZmNStSMTRDQ1g4anhFdmRYcU1WDQpLL0dqDQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0t"
  
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

      public_key = OpenSSL::X509::Certificate.new(Base64.decode64(CERT_STRING)).public_key
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
