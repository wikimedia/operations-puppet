# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
require "rspec-puppet/cache"

describe "openstack::nova::fullstack::monitor" do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, facts|
    context "On #{os}" do
      supported_openstacks = ["bobcat"]
      supported_openstacks.each do |openstack_version|
        context "On openstack #{openstack_version}" do
          let(:facts) { facts }
          it { should compile }
        end
      end
    end
  end
end
