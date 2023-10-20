#!/usr/bin/ruby
# SPDX-License-Identifier: Apache-2.0

require 'puppet'
require_relative '../modules/wmflib/lib/puppet/functions/wmflib/compile_redirects'
abort "Usage: #{$PROGRAM_NAME} DAT_FILE [apache|nginx]" if ARGV.length < 1 || ARGV.length > 2
if ARGV.length == 1
  web_server = 'apache'
else
  web_server = ARGV[1]
end
parser = DomainRedirects::Parser.new(File.read(ARGV[0]), web_server)
parser.parse_to(STDOUT)
