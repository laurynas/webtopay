require 'mokejimai'
require 'mokejimai_helper'
ActionController::Base.send(:include, Mokejimai)
ActionView::Base.send(:include, MokejimaiHelper)
