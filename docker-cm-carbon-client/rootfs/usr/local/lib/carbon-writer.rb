#!/usr/bin/ruby
#
#  (c) 2017 CoreMedia (Bodo Schulz)
#
# 1.2.0

# require_relative 'carbon-data'
require_relative 'carbon-writer/client'

# -------------------------------------------------------------------------------------------------

module CarbonWriter

  def self.version
    CarbonWriter::VERSION
  end

  def self.new( options )
    Client.new( options )
  end

end

# EOF
