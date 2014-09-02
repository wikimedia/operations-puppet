# == Function: mw_hhvm_catchall
#
# === Description
#
# Outputs the apache configuration directives that set up proxying of
# most requests to the HHVM backend.
#
# === Arguments
#
# Takes two optional arguments:
#
# - The HHVM server host (defaults to 127.0.0.1)
# - The HHVM server port (defaults to 9000)
#
# Whenever called, this function will output a string that can be
# directly used in your template
#
# == Examples
#
#     mw_hhvm_catchall()
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
              :mw_hhvm_catchall,
              :type => :rvalue,
              :doc => <<-END
Outputs the apache configuration for proxying all PHP files to HHVM.
Function parameters are:

 hhvm_host - the HHVM fastcgi server host
 hhvm_port - the HHVM fastcgi server port

Examples:

   mw_hhvm_catchall() # sets up proxying to fcgi://127.0.0.1:9000
END
              ) do |args|
    if args.length > 2
      raise Puppet::ParseError, 'mw_hhvm_catchall() takes at most 2 arguments'
    end

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
        RewriteEngine On
        # Execute all PHP and Hack files via HHVM
        <FilesMatch "\.(php|hh)$">
            RewriteRule ^(.*)$ fcgi://#{hhvm_host_port}$1 [P]
        </FilesMatch>
    </IfDefine>
VHOST
  end
end
