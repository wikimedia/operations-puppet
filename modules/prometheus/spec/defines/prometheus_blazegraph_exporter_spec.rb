# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::blazegraph_exporter', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:title) { 'wdqs-blazegraph' }
      let(:facts) { os_facts }
      let(:params) do
        {
          nginx_port: 80,
          blazegraph_port: 9999,
          prometheus_port: 9193,
          blazegraph_main_ns: 'wdq',
          collect_via_nginx: false
        }
      end
      let(:pre_condition) do
        "file { '/usr/local/bin/prometheus-blazegraph-exporter': ensure => file }"
      end

      it { is_expected.to compile }
      it do
        is_expected.to contain_systemd__service('prometheus-blazegraph-exporter-wdqs-blazegraph')
          .with_content(/^BindsTo=wdqs-blazegraph\.service$/)
          .with_content(/^WantedBy=wdqs-blazegraph\.service$/)
      end
    end
  end
end
