module MokejimaiHelper
  def macro_form(params, &block)
    fields = {:merchantid => "", :orderid => "1", :lang => 'LIT', :amount => 0, :currency => 'LTL', 
              :accepturl => 'http://google.com', :cancelurl => 'http://yahoo.com', :callbackurl => 'http://yourdomain.com', 
              :test => 0}
    fields.merge!(params)
    concat "<form action=\"https://www.mokejimai.lt/pay/\" method=\"post\" style=\"padding:0px;margin:0px\">"
    fields.each_pair {|k,v| concat hidden_field_tag(k, v) if !v.nil? }
    yield if block_given?
    concat "</form>"
  end
end