require 'jagamo/helper'
require 'jagamo/controller'

module Jagamo
  VERSION = '4.4sh'.freeze

  mattr_accessor :account
  mattr_accessor :path
  mattr_accessor :cookie

  Jagamo.path   = 'ga'
  Jagamo.cookie = '__utmmobile'
end
