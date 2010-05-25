module WebToPayHelper
  def macro_form(params, &block)
    fields = {:orderid => "1", :lang => 'LIT', :amount => 0, :currency => 'LTL', 
              :accepturl => 'http://google.com', :cancelurl => 'http://yahoo.com', :callbackurl => 'http://yourdomain.com',
              :projectid => WebToPay.config.project_id,
              :sign_password => WebToPay.config.sign_password,
              :test => 0}
              
    fields.merge!(params)
    
    request = WebToPay::Api.build_request(fields)
    
    concat "<form action=\"https://www.mokejimai.lt/pay/\" method=\"post\" style=\"padding:0px;margin:0px\">"
    request.each_pair {|k,v| concat hidden_field_tag(k, v) if !v.nil? }
    yield if block_given?
    concat "</form>"
  end
end
