# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "redis::monitoring::nrpe_instance", :type => :define do
  on_supported_os(WMFConfig.test_on(10)).each do |os|
    context "On #{os}" do
      let(:title) { "12345" }
      let(:params) do
        {
          replica_warning: 75,
          replica_critical: 750,
        }
      end
      context "with ensure present" do
        it do
          is_expected.to contain_nrpe__monitor_service("redis_status_on_port_12345").with(
            nrpe_command: "/usr/bin/sudo /usr/local/lib/nagios/plugins/nrpe_check_redis 12345 75 750",
            ensure: "present"
          )
        end
      end
    end
  end
end
