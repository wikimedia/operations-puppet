require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'profile::services_proxy' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) {
        facts.merge(
          {
            :numa =>
            {
              :device_to_htset => {:lo => []},
              :device_to_node  => {:lo => ["a", "test"]}
            }
          }
        )
      }
      let(:node_params) {
        { :site => 'testsite', :realm => 'production',
          :test_name => 'services_proxy',
          :initsystem => 'systemd',
          :numa_networking => 'off',
          :cluster => 'test'
        }
      }
#      let(:pre_condition) {
#        'class profile::base { $notifications_enabled = true }; include profile::base'
#      }
      context "with ensure present" do
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_nginx__site('upstream_proxies')
                           .with_ensure('present')
                           .with_content(/upstream foobar_testsite/)
        }
        it {
          is_expected.to contain_class('profile::tlsproxy::instance')
        }
      end
      context "with ensure absent" do
        let(:params) {
          {:ensure => 'absent'}
        }
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_nginx__site('upstream_proxies')
                           .with_ensure('absent')
        }
        it {
          is_expected.not_to contain_class('tlsproxy::instance')
        }
      end
    end
  end
end
