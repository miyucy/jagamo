require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require("jagamo")

class GoogleAnalytics
  def self.call(env)
    Jagamo::Controller.new(env).run
  end
end
