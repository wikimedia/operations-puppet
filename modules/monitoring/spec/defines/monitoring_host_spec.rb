require_relative '../../../../rake_modules/spec_helper'

describe 'monitoring::host' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge!(
          ipaddress: '192.0.2.42',
          hostname: 'ahost',
          lldp_parent: 'ahosts_parent',
          has_ipmi: true,
          ipmi_lan: {'ipaddress' => '198.51.100.42' }
        )
      end
      let(:node_params) { {'cluster' => 'ci', 'site' => 'eqiad'} }
      let(:title) { 'ahost' }

      context 'with a standard physical host' do
        let(:facts) { super().merge(is_virtual: false) }

        it { should compile }

        describe 'with no parameters' do
          subject { exported_resources }
          it do
            should contain_nagios_host('ahost').with(
              'host_name'  => 'ahost',
              'parents'    => 'ahosts_parent',
              'icon_image' => 'vendors/debian.png',
              'address'    => '192.0.2.42'
            )
            should contain_nagios_host('ahost.mgmt').with(
              'host_name'  => 'ahost.mgmt',
              'address'    => '198.51.100.42'
            )
          end
        end

        describe 'with a parents parameters' do
          let(:params) {
            {
              :parents => 'aparent',
            }
          }

          subject { exported_resources }
          it do
            should contain_nagios_host('ahost').with(
              'host_name'  => 'ahost',
              'parents'    => 'aparent',
              'icon_image' => 'vendors/debian.png',
              'address'    => '192.0.2.42'
            )
            should contain_nagios_host('ahost.mgmt').with(
              'host_name'  => 'ahost.mgmt',
              'address'    => '198.51.100.42'
            )
          end
        end
      end

      context 'with a standard virtual host' do
        let(:facts) { super().merge(is_virtual: true, has_ipmi: false) }

        it { should compile }
        describe 'with no parameters' do
          subject { exported_resources }
          it do
            should contain_nagios_host('ahost').with(
              'host_name'  => 'ahost',
              'parents'    => nil,
              'icon_image' => 'vendors/debian.png',
              'address'    => '192.0.2.42'
            )
            should_not contain_nagios_host('ahost.mgmt')
          end
        end
        describe 'with a parents parameters' do
          let(:params) {
            {
              :parents => 'aparent',
            }
          }
          subject { exported_resources }
          it do
            should contain_nagios_host('ahost').with(
              'host_name'  => 'ahost',
              'parents'    => 'aparent',
              'icon_image' => 'vendors/debian.png',
              'address'    => '192.0.2.42'
            )
            should_not contain_nagios_host('ahost.mgmt')
          end
        end
      end

      context 'with an icinga host' do
        let(:pre_condition){
          """
    class profile::base { $notifications_enabled = '1' }
    include ::profile::base
    class { 'icinga': icinga_user => 'icinga', icinga_group => 'icinga' }
          """
        }
        let(:node_params) { {'cluster' => 'ci', 'site' => 'eqiad'} }

        describe 'monitoring itself' do
          let(:title) { 'icingahost' }
          let(:facts) { super().merge(is_virtual: false, hostname: 'icingahost') }

          it do
            should contain_nagios_host('icingahost').with(
              'host_name'  => 'icingahost',
              'parents'    => 'ahosts_parent',
              'icon_image' => 'vendors/debian.png',
              'address'    => '192.0.2.42'
            )
            should contain_nagios_host('icingahost.mgmt').with(
              'host_name'  => 'icingahost.mgmt',
              'address'    => '198.51.100.42'
            )
          end
        end

        describe 'monitoring a service, no params' do
          let(:title) { 'service.svc.wmnet' }
          it do
            should contain_nagios_host('service.svc.wmnet').with(
              'host_name'  => 'service.svc.wmnet',
              'parents'    => nil,
              'icon_image' => nil,
              'address'    => '192.0.2.42'
            )
            should_not contain_nagios_host('service.svc.wmnet.mgmt')
          end
        end
        describe 'monitoring a service, with ip_address,parents' do
          let(:title) { 'service.svc.wmnet' }
          let(:params) {
            { :ip_address => '4.3.2.1',
              :parents    => 'service_parent',
          }
          }
          it do
            should contain_nagios_host('service.svc.wmnet').with(
              'host_name'  => 'service.svc.wmnet',
              'parents'    => 'service_parent',
              'icon_image' => nil,
              'address'    => '4.3.2.1'
            )
            should_not contain_nagios_host('service.svc.wmnet.mgmt')
          end
        end
        describe 'monitoring a service, with fqdn' do
          let(:title) { 'service.svc.wmnet' }
          let(:params) {
            { :host_fqdn => 'blah.foo.bar',
          }
          }
          it do
            should contain_nagios_host('service.svc.wmnet').with(
              'host_name'  => 'service.svc.wmnet',
              'parents'    => nil,
              'icon_image' => nil,
              'address'    => 'blah.foo.bar'
            )
            should_not contain_nagios_host('service.svc.wmnet.mgmt')
          end
        end
      end
    end
  end
end
