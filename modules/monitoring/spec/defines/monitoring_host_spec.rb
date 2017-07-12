require 'spec_helper'

describe 'monitoring::host' do
  before(:each) do
    Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |_|
      'fake_secret'
    }
  end
  # We abuse RSpec a bit throughout the spec setting site to a fact
  # Unfortunately RSpec node level parameters do not seem to work
  context 'with a standard physical host' do
    let(:facts) {
      {
        :hostname        => 'ahost',
        :operatingsystem => 'Debian',
        :ipaddress       => '1.2.3.4',
        :is_virtual      => false,
        :lldp_parent     => 'ahosts_parent',
        :has_ipmi        => true,
        :ipmi_lan        => { :ipaddress => '2.2.2.2', },
        :site            => 'blabla',
      }
    }
    let(:title) { 'ahost' }
    it { should compile }

    describe 'with no parameters' do
      subject { exported_resources }
      it do
        should contain_nagios_host('ahost').with(
          'host_name'  => 'ahost',
          'parents'    => 'ahosts_parent',
          'icon_image' => 'vendors/debian.png',
          'address'    => '1.2.3.4'
        )
        should contain_nagios_host('ahost.mgmt').with(
          'host_name'  => 'ahost.mgmt',
          'address'    => '2.2.2.2'
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
          'address'    => '1.2.3.4'
        )
        should contain_nagios_host('ahost.mgmt').with(
          'host_name'  => 'ahost.mgmt',
          'address'    => '2.2.2.2'
        )
      end
    end
  end

  context 'with a standard virtual host' do
    let(:facts) {
      {
        :hostname        => 'ahost',
        :operatingsystem => 'Debian',
        :ipaddress       => '1.2.3.4',
        :is_virtual      => true,
        :lldp_parent     => 'ahosts_parent',
        :has_ipmi        => false,
      }
    }
    let(:title) { 'ahost' }

    it { should compile }
    describe 'with no parameters' do
      subject { exported_resources }
      it do
        should contain_nagios_host('ahost').with(
          'host_name'  => 'ahost',
          'parents'    => nil,
          'icon_image' => 'vendors/debian.png',
          'address'    => '1.2.3.4'
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
          'address'    => '1.2.3.4'
        )
        should_not contain_nagios_host('ahost.mgmt')
      end
    end
  end

  context 'with an icinga host' do
    let(:facts) {
      {
        :hostname        => 'icingahost',
        :operatingsystem => 'Debian',
        :ipaddress       => '1.2.3.4',
        :is_virtual      => false,
        :lldp_parent     => 'ahosts_parent',
        :has_ipmi        => true,
        :ipmi_lan        => { :ipaddress => '2.2.2.2', },
        :site            => 'blabla',
      }
    }
    let(:pre_condition) do
      '''
      include icinga
      class passwords::nagios::mysql {}
      '''
    end

    describe 'monitoring itself' do
      let(:title) { 'icingahost' }
      it do
        should contain_nagios_host('icingahost').with(
          'host_name'  => 'icingahost',
          'parents'    => 'ahosts_parent',
          'icon_image' => 'vendors/debian.png',
          'address'    => '1.2.3.4'
        )
        should contain_nagios_host('icingahost.mgmt').with(
          'host_name'  => 'icingahost.mgmt',
          'address'    => '2.2.2.2'
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
          'address'    => '1.2.3.4'
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
