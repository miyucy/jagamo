require 'digest/md5'
require 'ipaddr'
require 'typhoeus'

module Jagamo
  class Controller
    attr_reader :request

    def initialize(env)
      @request = Rack::Request.new(env)
    end

    def run
      return error unless check_path_info
      track_page_view
      success
    end

    def check_path_info
      Jagamo.path.present? && request.path_info =~ %r"^/#{Jagamo.path}"
    end

    def error
      [404, {}, ['']]
    end

    def success
      response = Rack::Response.new([response_data], 200, {
                                      'Content-Type'   => 'image/gif',
                                      'Cache-Control'  => 'private, no-cache, no-cache =Set-Cookie, proxy-revalidate',
                                      'Pragma'         => 'no-cache',
                                      'Expires'        => 'Wed, 17 Sep 1975 21:32:10 GMT',
                                    })
      response.set_cookie(Jagamo.cookie, :value => visitor_id, :expires => 2.years.since)
      response.finish
    end

    def response_data
      "GIF89a\001\000\001\000\200\377\000\377\377\377\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"
    end

    def track_page_view
      referer = request.params['utmr'].blank? ? '-' : request.params['utmr']
      path    = request.params['utmp'].blank? ? ''  : request.params['utmp']

      typh = Typhoeus::Request.new('http://www.google-analytics.com/__utm.gif',
                                   :params => {
                                     'utmwv'  => VERSION,
                                     'utmn'   => rand(0x7FFFFFFF),
                                     'utmac'  => request.params['utmac'],
                                     'utmcc'  => '__utma =999.999.999.999.999.1;',
                                     'utmhn'  => request.env['SERVER_NAME'],
                                     'utmr'   => referer,
                                     'utmp'   => path,
                                     'utmip'  => remote_addr,
                                     'utmvid' => visitor_id,
                                   },
                                   :headers => {
                                     'Accepts-Language' => request.env['HTTP_ACCEPT_LANGUAGE'],
                                   },
                                   :user_agent => request.env['HTTP_USER_AGENT'])
      Thread.new(typh) do |request|
        Typhoeus::Hydra.hydra.queue request
        Typhoeus::Hydra.hydra.run
      end
    end

    def remote_addr
      request.env['REMOTE_ADDR'].blank? ? '' : masked_remote_addr
    end

    def masked_remote_addr
      IPAddr.new(request.env['REMOTE_ADDR']).mask(24).to_s
    end

    GUIDS = %w(HTTP_X_DCMGUID HTTP_X_UP_SUBNO HTTP_X_JPHONE_UID HTTP_X_EM_UID).freeze
    def guid
      @guid ||= request.env.find{ |k, v| GUIDS.include?(k) && v.present? } || ""
    end

    def visitor_id
      return request.cookies[Jagamo.cookie] unless request.cookies[Jagamo.cookie].blank?
      @visitor_id ||= md5(guid == "" ? random_user_id : guid_user_id)
    end

    def random_user_id
      request.env['HTTP_USER_AGENT'] + ActiveSupport::SecureRandom.hex(23)
    end

    def guid_user_id
      guid + request.params['utmac']
    end

    def md5(str)
      "0x#{Digest::MD5.hexdigest(str)[0...16]}"
    end
  end
end
