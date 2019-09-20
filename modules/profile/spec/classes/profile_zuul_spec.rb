require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8'],
    }
  ]
}

describe 'profile::zuul::server' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node_params) { {
          :initsystem => 'systemd',
          :site => 'test_site',
          :cluster => 'test_cluster',
      } }
      default_params = {
          :conf_common => {},
          :conf_server => {},
          :email_server => 'localhost',
      }
      let(:pre_condition) {
          '''
          # Refered by monitoring::service
          class profile::base {
            $notifications_enabled = "1"
          }
          include profile::base
          '''
      }

      context 'service enabled' do
        let(:params) {
          default_params.merge({
            :service_enable => true,
            :service_ensure => 'running',
          })
        }
        it {
            should_not contain_systemd__mask('zuul.service')
        }
        it {
            should contain_systemd__unmask('zuul.service')
              .that_comes_before('Class[Zuul::Server]')
        }
        it {
            should contain_class('zuul::monitoring::server').with_ensure('present')
        }
      end

      context 'service disabled' do
        let(:params) {
          default_params.merge({
            :service_enable => false,
            :service_ensure => 'stopped',
          })
        }
        it {
            should contain_systemd__mask('zuul.service')
              .that_comes_before('Class[Zuul::Server]')
        }
        it {
            should contain_class('zuul::monitoring::server').with_ensure('absent')
        }
      end
    end
  end
end
