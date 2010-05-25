module WebToPay
  class << self
    attr_accessor :config
    
    def configure
      self.config ||= Configuration.new
      yield(config)
    end
  end
end