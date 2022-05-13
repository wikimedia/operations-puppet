# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker-rspec'

modules = [
  'git',
  'wmflib',
  'stdlib',
  'base',  # need base to have access to initsystem fact
  'systemd'
]
def install_modules(host, modules)
  module_root = File.expand_path(File.join(__dir__, '..'))
  install_dev_puppet_module_on(
    host, source: module_root, module_name: File.basename(module_root))
  modules.each do |m|
    source = File.expand_path(File.join(module_root, '..', m))
    install_dev_puppet_module_on(host, source: source, module_name: m)
  end
end
hosts.each do |host|
  # install puppet from debian repos
  step "install puppet on #{host}"
  host.install_package('puppet')
  step "Enable IPv6 on #{host}"
  on(host, 'sysctl net.ipv6.conf.all.disable_ipv6=0')
  install_modules(host, modules)
end
RSpec.configure do |c|
  c.formatter = :documentation
  # c.before :suite do
  #   hosts.each do |host|
  #   end
  # end
end
