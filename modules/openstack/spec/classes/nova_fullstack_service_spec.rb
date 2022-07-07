# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
require "rspec-puppet/cache"

describe "openstack::nova::fullstack::service" do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "On #{os}" do
      supported_openstacks = ["wallaby"]
      supported_openstacks.each do |openstack_version|
        context "On openstack #{openstack_version}" do
          let(:facts) { facts }
          let(:params) {
            {
              "active" => true,
              "password" => "dummypass",
              "region" => "dummyregion",
              "puppetmaster" => "dummy.puppet.master",
              "bastion_ip" => "127.1.1.1",
            }
          }
          context "When active" do
            it { should compile }
            it {
              should_not contain_file("/var/lib/prometheus/node.d/novafullstack.prom")
            }
          end
          context "When inactive" do
            let(:params) {
              super().merge({
                "active" => false,
              })
            }
            it {
              should contain_file("/var/lib/prometheus/node.d/novafullstack.prom").with_ensure("absent")
            }
          end
        end
      end
    end
  end
end
