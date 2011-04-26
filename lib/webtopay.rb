require 'webtopay/exception'
require 'webtopay/configuration'
require 'webtopay/api'
require 'webtopay_controller'
require 'webtopay_helper'

module WebToPay
  class << self
    attr_accessor :config

    def configure
      self.config ||= Configuration.new
      yield(config)
    end
  end
end

ActionController::Base.send(:include, WebToPayController)
ActionView::Base.send(:include, WebToPayHelper)

