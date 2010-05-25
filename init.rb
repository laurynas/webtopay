require 'webtopay'
require 'exception'
require 'configuration'
require 'api'
require 'webtopay_controller'
require 'webtopay_helper'

ActionController::Base.send(:include, WebToPayController)
ActionView::Base.send(:include, WebToPayHelper)
