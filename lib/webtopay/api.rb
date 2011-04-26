require 'digest/md5'
require 'openssl'
require 'open-uri'

module WebToPay
  class Api
    VERSION       = "1.2"
    PREFIX        = "wp_"
    CERT_PATH     = "http://downloads.webtopay.com/download/public.key"
    
    # Array structure:
    #  * name      – request item name.
    #  * maxlen    – max allowed value for item.
    #  * required  – is this item is required.
    #  * user      – if true, user can set value of this item, if false
    #                item value is generated.
    #  * isrequest – if true, item will be included in request array, if
    #                false, item only be used internaly and will not be
    #                included in outgoing request array.
    #  * regexp    – regexp to test item value.
    REQUEST_SPECS = [ [ :projectid,      11,     true,   true,   true,   /^\d+$/ ],
                      [ :orderid,        40,     true,   true,   true,   '' ],
                      [ :lang,           3,      false,  true,   true,   /^[a-z]{3}$/i ],
                      [ :amount,         11,     false,  true,   true,   /^\d+$/ ],
                      [ :currency,       3,      false,  true,   true,   /^[a-z]{3}$/i ],
                      [ :accepturl,      255,    true,   true,   true,   '' ],
                      [ :cancelurl,      255,    true,   true,   true,   '' ],
                      [ :callbackurl,    255,    true,   true,   true,   '' ],
                      [ :payment,        20,     false,  true,   true,   '' ],
                      [ :country,        2,      false,  true,   true,   /^[a-z]{2}$/i ],
                      [ :paytext,        255,    false,  true,   true,   '' ],
                      [ :p_firstname,    255,    false,  true,   true,   '' ],
                      [ :p_lastname,     255,    false,  true,   true,   '' ],
                      [ :p_email,        255,    false,  true,   true,   '' ],
                      [ :p_street,       255,    false,  true,   true,   '' ],
                      [ :p_city,         255,    false,  true,   true,   '' ],
                      [ :p_state,        20,     false,  true,   true,   '' ],
                      [ :p_zip,          20,     false,  true,   true,   '' ],
                      [ :p_countrycode,  2,      false,  true,   true,   /^[a-z]{2}$/i ],
                      [ :sign,           255,    true,   false,  true,   '' ],
                      [ :sign_password,  255,    true,   true,   false,  '' ],
                      [ :test,           1,      false,  true,   true,   /^[01]$/ ],
                      [ :version,        9,      true,   false,  true,   /^\d+\.\d+$/ ] ]

    # Array structure:
    # * name       – request item name.
    # * maxlen     – max allowed value for item.
    # * required   – is this item is required in response.
    # * mustcheck  – this item must be checked by user.
    # * isresponse – if false, item must not be included in response array.
    # * regexp     – regexp to test item value.
    MAKRO_RESPONSE_SPECS = [
                      [ :projectid,       11,     true,   true,   true,  /^\d+$/ ],
                      [ :orderid,         40,     false,  false,  true,  '' ],
                      [ :lang,            3,      false,  false,  true,  /^[a-z]{3}$/i ],
                      [ :amount,          11,     false,  false,  true,  /^\d+$/ ],
                      [ :currency,        3,      false,  false,  true,  /^[a-z]{3}$/i ],
                      [ :payment,         20,     false,  false,  true,  '' ],
                      [ :country,         2,      false,  false,  true,  /^[a-z]{2}$/i ],
                      [ :paytext,         0,      false,  false,  true,  '' ],
                      [ :_ss2,            0,      true,   false,  true,  '' ],
                      [ :_ss1,            0,      false,  false,  true,  '' ],
                      [ :name,            255,    false,  false,  true,  '' ],
                      [ :surename,        255,    false,  false,  true,  '' ],
                      [ :status,          255,    false,  false,  true,  '' ],
                      [ :error,           20,     false,  false,  true,  '' ],
                      [ :test,            1,      false,  false,  true,  /^[01]$/ ],
                      [ :p_email,         0,      false,  false,  true,  '' ],
                      [ :payamount,       0,      false,  false,  true,  '' ],
                      [ :paycurrency,     0,      false,  false,  true,  '' ],
                      [ :version,         9,      true,   false,  true,  /^\d+\.\d+$/ ],
                      [ :sign_password,   255,    false,  true,   false, '' ] ]
                      
    # Specification array for mikro response.
    #
    # Array structure:
    # * name       – request item name.
    # * maxlen     – max allowed value for item.
    # * required   – is this item is required in response.
    # * mustcheck  – this item must be checked by user.
    # * isresponse – if false, item must not be included in response array.
    # * regexp     – regexp to test item value.
    MIKRO_RESPONSE_SPECS = [
                      [ :to,              0,      true,   false,  true,  '' ],
                      [ :sms,             0,      true,   false,  true,  '' ],
                      [ :from,            0,      true,   false,  true,  '' ],
                      [ :operator,        0,      true,   false,  true,  '' ],
                      [ :amount,          0,      true,   false,  true,  '' ],
                      [ :currency,        0,      true,   false,  true,  '' ],
                      [ :country,         0,      true,   false,  true,  '' ],
                      [ :id,              0,      true,   false,  true,  '' ],
                      [ :_ss2,            0,      true,   false,  true,  '' ],
                      [ :_ss1,            0,      true,   false,  true,  '' ],
                      [ :test,            0,      true,   false,  true,  '' ],
                      [ :key,             0,      true,   false,  true,  '' ],
                      #[ :version,         9,      true,   false,  true,  /^\d+\.\d+$/ ] 
                      ]

    # Checks user given request data array.
    #
    # If any errors occurs, WebToPay::Exception will be raised.
    #
    # This method returns validated request array. Returned array contains
    # only those items from data, that are needed.
    #
    def self.check_request_data(data)
      request = {}
      data.symbolize_keys!
      
      REQUEST_SPECS.each do |spec|
        name, maxlen, required, user, isrequest, regexp = spec
        
        next unless user
        
        name = name.to_sym
        
        if required && data[name].nil?
          e               = Exception.new self._("'%s' is required but missing.", name)
          e.code          = Exception::E_MISSING
          e.field_name    = name
          raise e
        end
        
        unless data[name].to_s.empty?
          if (maxlen && data[name].to_s.length > maxlen)
            e             = Exception.new self._("'%s' value '%s' is too long, %d characters allowed.", 
                                                 name, data[name], maxlen)
            e.code        = Exception::E_MAXLEN
            e.field_name  = name
            raise e
          end

          if ('' != regexp && !data[name].to_s.match(regexp)) 
            e             = Exception.new self._("'%s' value '%s' is invalid.", name, data[name])
            e.code        = Exception::E_REGEXP
            e.field_name  = name
            raise e
          end
        end
        
        if isrequest && !data[name].nil?
          request[name] = data[name]
        end
      end
      
      return request
    end
    
    # Puts signature on request data hash
    def self.sign_request(request, password)
      fields = [ :projectid, :orderid, :lang, :amount, :currency,
                 :accepturl, :cancelurl, :callbackurl, :payment, :country,
                 :p_firstname, :p_lastname, :p_email, :p_street,
                 :p_city, :p_state, :p_zip, :p_countrycode, :test,
                 :version ]
                  
      request.symbolize_keys!
      
      data = ''
      
      fields.each do |key|
        val = request[key].to_s
        
        unless val.strip.blank?
          data+= sprintf("%03d", val.length) + val.downcase
        end
      end
      
      request[:sign] = Digest::MD5.hexdigest(data + password)
      
      return request
    end
    
    # Builds request data array.
    #
    # This method checks all given data and generates correct request data
    # array or raises WebToPayException on failure.
    #
    # Method accepts single parameter $data of array type. All possible array
    # keys are described here:
    # https://www.mokejimai.lt/makro_specifikacija.html
    def self.build_request(data)
      data.symbolize_keys!
      
      request           = self.check_request_data(data)
      request[:version] = self::VERSION
      request           = self.sign_request(request, data[:sign_password])
      
      return request 
    end
    
    # Checks and validates response from WebToPay server.
    #
    # This function accepts both mikro and makro responses.
    #
    # First parameter usualy should by params hash
    #
    # Description about response can be found here:
    # makro: https://www.mokejimai.lt/makro_specifikacija.html
    # mikro: https://www.mokejimai.lt/mikro_mokejimu_specifikacija_SMS.html
    #
    # If response is not correct, WebToPay::Exception will be raised.
    def self.check_response(query, user_data =  {}) 
      @@verified = false;
      
      response = self.query_to_response(query)
      response = self.get_prefixed(response, self::PREFIX)
      response.symbolize_keys!

      # *get* response type (makro|mikro)
      type, specs = self.get_specs_for_response(response)

      self.check_response_data(response, user_data, specs)
      @@verified = 'RESPONSE';

      # *check* response
      if :makro == type && response[:version] != self::VERSION
        e = Exception.new(self._('Incompatible library and response versions: ' +
                                 'libwebtopay %s, response %s', self::VERSION, response[:version]))
        e.code = Exception::E_INVALID
        raise e
      end

      if :makro == type
        @@verified = 'RESPONSE VERSION ' + response[:version] + ' OK'
      end

      orderid   = :makro == type ? response[:orderid] : response[:id]
      password  = user_data[:sign_password]

      if self.check_response_cert(query)
        @@verified = 'SS2 public.key'
      end

      # *check* status
      if :makro == type && 1 != response[:status].to_i
        e = Exception.new(self._('Returned transaction status is %d, successful status ' +
                                 'should be 1.', response[:status]))
        e.code = Exception::E_INVALID
        raise e
      end

      return response
    end
    
    def self.check_response_data(response, mustcheck_data, specs) 
      resp_keys = []
      
      response.symbolize_keys!
      mustcheck_data.symbolize_keys!
      
      specs.each do |spec|
        name, maxlen, required, mustcheck, is_response, regexp = spec
        
        if required && response[name].nil?
          e             = Exception.new(self._("'%s' is required but missing.", name))
          e.code        = Exception::E_MISSING
          e.field_name  = name
          raise e
        end

        if mustcheck
          if mustcheck_data[name].nil?
            e             = Exception.new(self._("'%s' must exists in array of second " +
                                                 "parameter of checkResponse() method.", name))
            e.code        = Exception::E_USER_PARAMS
            e.field_name  = name
            raise e
          end

          if is_response
            if response[name].to_s != mustcheck_data[name].to_s
              e = Exception.new(self._("'%s' yours and requested value is not " +
                                       "equal ('%s' != '%s') ",
                                       name, mustcheck_data[name], response[name]))
              e.code        = Exception::E_INVALID
              e.field_name  = name
              raise e
            end
          end
        end

        if !response[name].to_s.empty?
          if maxlen > 0 && response[name].to_s.length > maxlen
            e = Exception.new(self._("'%s' value '%s' is too long, %d characters allowed.",
                                     name, response[name], maxlen))
            e.code        = Exception::E_MAXLEN
            e.field_name  = name
            raise e
          end

          if '' != regexp && !response[name].to_s.match(regexp)
            e = new WebToPayException(self._("'%s' value '%s' is invalid.", 
                                                name, response[name]))
            e.code        = Exception::E_REGEXP
            e.field_name  = name
            raise e
          end
        end

        resp_keys << name unless response[name].nil?
      end

      # Filter only parameters passed from webtopay
      _response = {}
      
      response.keys.each do |key|
        _response[key] = response[key] if resp_keys.include?(key)  
      end

      return _response
    end
    
    # Return type and specification of given response array.
    def self.get_specs_for_response(response) 
      response.symbolize_keys!
      
      if ( !response[:to].nil? && !response[:from].nil? && 
           !response[:sms].nil? && response[:projectid].nil? )
          
          type  = :mikro
          specs = self::MIKRO_RESPONSE_SPECS
      else
          type  = :makro
          specs = self::MAKRO_RESPONSE_SPECS
      end

      return [ type, specs ]
    end
    
    # Check if response certificate is valid
    def self.check_response_cert(query)
      public_key = self.get_public_key
      
      if (!public_key)
        e = Exception.new(self._('Can\'t get openssl public key for %s', cert))
        e.code = Exception::E_INVALID
        raise e
      end

      res   = self.query_to_response(query)
      res   = self.get_prefixed(res, PREFIX).symbolize_keys
      keys  = self.get_query_keys(query)
      skip  = [ :_ss2, :controller, :action ]
      _SS2  = ''
      
      keys.each do |key|
        if !skip.include?(key)
          _SS2 << res[key].to_s + '|'
        end        
      end
      
      if !public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(res[:_ss2]), _SS2)  
        e       = Exception.new(self._('Can\'t verify SS2'))
        e.code  = Exception::E_INVALID
        raise e
      end

      return true
    end
    
    def self.get_public_key
      OpenSSL::X509::Certificate.new(open(CERT_PATH).read).public_key
    end
    
    def self.get_prefixed(data, prefix) 
      return data if prefix.to_s.blank?
      
      ret = {}
      reg = /^#{prefix}/
      
      data.stringify_keys!
      
      data.each_pair do |key, val|
        if key.length > prefix.length && key.match(reg)
          ret[key.gsub(reg, '')] = val
        end
      end
      
      return ret
    end
    
    def self.query_to_response(query)
      response = {}
      
      query.split(/&/).each do |item|
        key, val = item.split(/\=/)
        response[key] = CGI.unescape(val.to_s)
      end
      
      return response
    end
    
    def self.get_query_keys(query)
      query.split(/&/).collect { |i| i.split(/\=/).first.gsub(/^#{PREFIX}/, '').to_sym }
    end
    
    # I18n support.
    def self._(*args)
      if args.length > 1 
        return send(:sprintf, *args)
      else
        return args[0]
      end
    end
  end
end
