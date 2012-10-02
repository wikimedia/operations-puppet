#!/usr/bin/env ruby
#
# Sample script to expand the Gerrit hookconfig.py template. The resulting
# expansion is simply printed to STDOUT.
#
# Script is used by hookhelper_test.py to create the 'hookconfig' python module
#

# Parameters for hookconfig unit testing
gerrit_pass = "secretpassword"
hostname    = "hostname.ssh.example.net"
sshport     = "7777"

# Expand the hookconfig.py.erb templates using the parameter defined above
require 'erb'
template = ERB.new( File.read("../../../templates/gerrit/hookconfig.py.erb") );

# Print expanded template to standard output
puts template.result;
