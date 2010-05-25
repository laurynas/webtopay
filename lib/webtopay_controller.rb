module WebToPayController  
  module ClassMethods
    def webtopay(*actions)
      before_filter :webtopay_check
      write_inheritable_array(:actions, actions)
      
      attr_reader :webtopay_response
    end
  end
  
  def self.included(controller)
    controller.extend(ClassMethods)
  end
  
  protected
  
  def webtopay_required?
    (self.class.read_inheritable_attribute(:actions) || []).include?(action_name.to_sym)
  end

  def webtopay_check
    if webtopay_required?
      begin
        
        @webtopay_response = WebToPay::Api.check_response(request.query_string, {
          :projectid      => WebToPay.config.project_id,
          :sign_password  => WebToPay.config.sign_password
        })
        
      rescue WebToPay::Exception => e
        render :text => e.message, :status => 500
      end 
    end
  end
end
