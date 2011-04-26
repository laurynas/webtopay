require 'webtopay/webtopay'
require 'webtopay/exception'
require 'webtopay/configuration'
require 'webtopay/api'
require 'webtopay_controller'
require 'webtopay_helper'

ActionController::Base.send(:include, WebToPayController)
ActionView::Base.send(:include, WebToPayHelper)

