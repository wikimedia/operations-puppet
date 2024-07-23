require_relative '../../../../rake_modules/spec_helper'

describe 'profile::lvs::realserver' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      context "without conftool" do
        let(:params) {
          {
            'pools' => {'text' => {'service' => 'nginx'}},
            'use_conftool' => false,
            'poolcounter_backends' => [],
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_class('lvs::realserver').with_realserver_ips([
            '208.80.154.224',
            '208.80.154.225',
            '2620:0:861:ed1a::1',
            '2620:0:861:ed1a::2'
          ])
        end
      end
      context "with conftool" do
        let(:params) {
          {
            'pools' => {
              'jobrunner' => {'services' => ['apache2', 'php', 'mcrouter', 'nginx']},
            },
            'use_conftool' => true,
            'poolcounter_backends' => [
              {'label' => 't', 'fqdn' => 'test.example.org'},
              {'label' => 't1', 'fqdn' => 'test1.example.org'},
            ]

          }
        }
        let(:pre_condition) {
          "class profile::conftool::client {}"
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('lvs::realserver')
                              .with_realserver_ips(['10.2.2.26'])
        }
        it { is_expected.to contain_conftool__scripts__safe_service_restart('nginx')
                              .with_lvs_pools(['jobrunner'])
        }
        it { is_expected.to contain_file('/usr/local/sbin/restart-apache2')
                              .with_content(/--pools jobrunner --services apache2/)
                              .with_content(/--max-concurrency [1-9]/)
        }
        it { is_expected.to contain_class('poolcounter::client::python')
                              .with_ensure('present')
        }
        it { is_expected.to contain_file('/usr/local/bin/depool-nginx')
                              .with_content(/\-\-depool/)
        }
      end
    end
  end
end
