require 'spec_helper'

describe 'monitoring::host' do
  context 'with a standard physical host' do
    let(:facts) {
      {
        :hostname        => 'ahost',
        :operatingsystem => 'Debian',
        :ipaddress       => '1.2.3.4',
        :is_virtual      => false,
        :lldp_parent     => 'ahosts_parent',
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
          'address'    => '1.2.3.4',
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
          'address'    => '1.2.3.4',
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
          'address'    => '1.2.3.4',
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
          'address'    => '1.2.3.4',
        )
      end
    end
  end

  context 'with an icinga host monitoring itself' do
    let(:facts) {
      {
        :hostname        => 'ahost',
        :operatingsystem => 'Debian',
        :ipaddress       => '1.2.3.4',
        :is_virtual      => false,
        :lldp_parent     => 'ahosts_parent',
      }
    }
    let(:title) { 'ahost' }
    let(:pre_condition) { 'include icinga'}
    describe 'with no parameters' do
      it do
        should contain_nagios_host('ahost').with(
          'host_name'  => 'ahost',
          'parents'    => 'ahosts_parent',
          'icon_image' => 'vendors/debian.png',
          'address'    => '1.2.3.4',
        )
      end
    end
  end
end
