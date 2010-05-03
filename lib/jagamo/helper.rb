module Jagamo
  module Helper
    def google_analytics_tracker(options={})
      return if Jagamo.account.blank?
      referer = request.env['HTTP_REFERER']
      referer = '-' if referer.blank?
      param = {
        :utmac => Jagamo.account,
        :utmn  => rand(0x7FFFFFFF),
        :utmr  => url_encode(referer),
        :guid  => 'ON',
      }
      path = request.env['REQUEST_URI']
      path = url_for(params) if path.blank?
      param[:utmp] = url_encode(path) if path.present?

      image_tag('/' + Jagamo.path + '?' + param_to_query(param), { :size => '1x1', :alt => '' }.update(options))
    end

    private

    def param_to_query(param)
      param.map{ |v| v * '=' } * '&'
    end
  end
end
