# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "profile::wmcs::metricsinfra::haproxy" do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          "prometheus_alertmanager_hosts" => [],
          "alertmanager_active_host" => "dummy.alertmanager.host",
          "thanos_fe_hosts" => [],
          "config_manager_hosts" => [],
        }
      }

      it { is_expected.to compile.with_all_deps }

      context "Adds all passed prometheus_alertmanager_hosts" do
        let(:params) {
          super().merge({
            "prometheus_alertmanager_hosts" => ["host1", "host2"],
          })
        }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host1:9093/) }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host2:9093/) }
      end

      context "Adds all passed thanos_fe_hosts" do
        let(:params) {
          super().merge({
            "thanos_fe_hosts" => ["host1", "host2"],
          })
        }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host1:10902/) }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host2:10902/) }
      end

      context "Adds all passed config_manager_hosts" do
        let(:params) {
          super().merge({
            "config_manager_hosts" => ["host1", "host2"],
          })
        }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host1:80/) }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host2:80/) }
      end

      context "If alertmanager_active_host matches one in prometheus_alertmanager_hosts, it adds it for karma ui" do
        let(:params) {
          super().merge({
            "prometheus_alertmanager_hosts" => ["host1", "host2"],
            "alertmanager_active_host" => "host1",
          })
        }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host1:80 check$/) }
        it { is_expected.to contain_file("/etc/haproxy/conf.d/prometheus.cfg").with_content(/host2:80 check backup$/) }
      end
    end
  end
end
