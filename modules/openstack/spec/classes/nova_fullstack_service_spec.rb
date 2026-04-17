# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
require "rspec-puppet/cache"

describe "openstack::nova::fullstack::service" do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, facts|
    context "On #{os}" do
      supported_openstacks = ["flamingo"]
      supported_openstacks.each do |openstack_version|
        context "On openstack #{openstack_version}" do
          let(:facts) { facts }
          let(:params) {
            {
              "active" => true,
              "password" => "dummypass",
              "region" => "dummyregion",
              "bastion_ip" => "127.1.1.1",
              "deployment" => "eqiad1",
              "resolvers" => ["192.0.2.2", "::1"],
              "network" => "d8a16ddf-c01f-4f22-8b67-8ed18b4b1b45",
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
