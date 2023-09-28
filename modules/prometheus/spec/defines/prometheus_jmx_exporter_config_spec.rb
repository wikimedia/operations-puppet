# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'prometheus::jmx_exporter_config', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      let(:params) { { class_name: 'foo::bar', dest: '/foobar.yaml' } }
      let(:title) { 'my_prometheus_server' }
      let(:pre_condition) do
        """function wmflib::puppetdb_query($pql) {
          [
            {
              'certname' => 'kafka-test1008.eqiad.wmnet',
              'parameters' => {
                'port' =>  7800,
                'labels' =>  {'kafka_cluster' =>  'test-eqiad'},
                'hostname' =>  'kafka-test1008'
              }
            },
            {
              'certname' => 'kafka-test1009.eqiad.wmnet',
              'parameters' => {
                'port' =>  7800,
                'labels' =>  {'kafka_cluster' =>  'test-eqiad'},
                'hostname' =>  'kafka-test1009'
              }
            },
            {
              'certname' => 'kafka-test1010.eqiad.wmnet',
              'parameters' => {
                'port' =>  7800,
                'labels' =>  {'kafka_cluster' =>  'test-eqiad'},
                'hostname' =>  'kafka-test1010'
              }
            }
          ]
        }
        function wmflib::get_clusters($x) {
          {
            'test-eqiad' => { 'eqiad' => [
              'kafka-test1008.eqiad.wmnet',
              'kafka-test1009.eqiad.wmnet',
              'kafka-test1010.eqiad.wmnet'
            ]}
          }
        }"""
      end

      context 'simple example' do
        it { is_expected.to compile }
        it do
          is_expected.to contain_file('/foobar.yaml')
            .with_content(/
                          targets:\s+
                          -\skafka-test1008:7800\s+
                          -\skafka-test1009:7800\s+
                          -\skafka-test1010:7800\s+
                          labels:\s+
                            cluster:\stest-eqiad\s+
                            kafka_cluster:\stest-eqiad
                          /x)
        end
      end
    end
  end
end
