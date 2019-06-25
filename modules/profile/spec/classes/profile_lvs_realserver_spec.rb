require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'profile::lvs::realserver' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      context "without conftool" do
        let(:node_params) { { :site => 'testsite', :realm => 'production',
                              :test_name => 'lvs_realserver'} }

        let(:params) {
          {
            'pools' => {'text' => {'service' => 'nginx'}},
            'use_conftool' => false
          }
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('lvs::realserver')
                              .with_realserver_ips(["1.1.1.1", "2620:0:861:102:1:1:1:1"])
        }
      end
      context "with conftool" do
        let(:node_params) { { :site => 'eqiad', :realm => 'production',
                              :test_name => 'lvs_realserver'} }
        let(:params) {
          {
            'pools' => {
              'apaches' => {'services' => ['apache2', 'php', 'mcrouter']},
              'appservers-https' => {'services' => ['apache2', 'php', 'mcrouter', 'nginx']},
            },
            'use_conftool' => true,
            'use_safe_restart' => true,
          }
        }
        let(:pre_condition) {
          "class profile::conftool::client {}"
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('lvs::realserver')
                              .with_realserver_ips(["8.8.8.8", "2620:0:861:102:8:8:8:8"])
        }
        it { is_expected.to contain_conftool__scripts__safe_service_restart('nginx')
                              .with_lvs_pools(['appservers-https'])
        }
        it { is_expected.to contain_file('/usr/local/sbin/restart-apache2')
                              .with_content(%r{http:\/\/lvs1016:9090\/pools\/apaches_80})
        }
      end
    end
  end
end
