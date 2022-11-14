# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker-rspec'

def install_modules(host, modules, vendor_modules); end
module_root = File.expand_path(File.join(__dir__, '..'))
hosts.each do |host|
  on(host, 'git -C /etc/puppet/code/environments/production fetch')
  on(host, 'git -C /etc/puppet/code/environments/production reset --hard origin/production')
  install_dev_puppet_module_on(
    host, source: module_root, module_name: File.basename(module_root)
  )
end
RSpec.configure do |c|
  c.formatter = :documentation
  # c.before :suite do
  #   hosts.each do |host|
  #   end
  # end
end
