class JagamoGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.directory 'app/metal'
      m.template 'metal.rb', 'app/metal/google_analytics.rb'
    end
  end
end
