# == Function: mw_hhvm_proxy
#
# === Description
#
# Outputs the apache configuration directives that set up proxying of
# most requests to the HHVM backend.
#
# === Arguments
#
# Takes three arguments:
#
# - The document root of the current VirtualHost stanza
# - The HHVM server host (defaults to localhost)
# - The HHVM server port (defaults to 9000)
#
# Whenever called, this function will output a string that can be
# directly used in your template
#
# == Examples
#
#     mw_hhvm_proxy('/var/www')
#
# == License
#
# Author: Giuseppe Lavagetto
# Copyright 2014 Wikimedia Foundation
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'puppet/util/package'

module Puppet::Parser::Functions
  newfunction(
              :mw_hhvm_proxy,
              :type => :rvalue,
              :doc => <<-END
Outputs the apache configuration for proxying mediawiki to HHVM.
Function parameters are:
 docroot - the document root of the VirtualHost
 hhvm_host - the HHVM fastcgi server host
 hhvm_port - the HHVM fastcgi server port

Examples:

   mw_hhvm_proxy('/var/www') # sets up proxying to fcgi://127.0.0.1:9000/var/www
END
              ) do |args|
    if args.length < 1 || args.length > 3
      raise Puppet::ParseError, 'mw_hhvm_proxy() requires at least 1 argument'
    end

    docroot = args.shift

    if args.length >= 1
      hhvm_host = args.shift
    else
      hhvm_host = '127.0.0.1'
    end

    if args.length == 1
      hhvm_port = args.shift
    else
      hhvm_port = '9000'
    end

    hhvm_host_port = [hhvm_host, hhvm_port].join(':')

    return <<-VHOST
    <IfDefine HHVM>
        # Main ProxyPass rules for mediawiki served via hhvm.
        ProxyPass /wiki  /fcgi://#{hhvm_host_port}#{docroot}/w/index.php
        ProxyPass /w/extensions !
        ProxyPassMatch ^/w/(.*\.(php|hh))$  fcgi://#{hhvm_host_port}#{docroot}/w/$1  retry=0
    </IfDefine>
VHOST
  end
end
