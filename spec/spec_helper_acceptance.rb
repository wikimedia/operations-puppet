# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker-rspec'

REALM = ENV.fetch('PUPPET_REALM', 'production')
ROLE = ENV.fetch('PUPPET_ROLE', 'insetup')
HOSTNAME = ENV.fetch('PUPPET_HOSTNAME', "#{ROLE}1001.eqiad.wmnet")
SITE = ENV.fetch('PUPPET_SITE', 'eqiad')
PP_HEADER = <<-PP
$realm = '#{REALM}'
$site = '#{SITE}'
$numa_networking = 'off'
$ntp_peers = lookup('ntp_peers')
role('#{ROLE}')
PP
REPO_ROOT = File.expand_path(File.join(__dir__, '..'))

def bootstrap(host)
  on(host, "/production/utils/beaker_bootstrap.rb #{HOSTNAME}")
  on(host, 'apt-get install -y vim')
end

hosts.each do |host|
  bootstrap(host)
end

RSpec.configure do |c|
  c.formatter = :documentation
  # c.before :suite do
  #   hosts.each do |host|
  #   end
  # end
end
