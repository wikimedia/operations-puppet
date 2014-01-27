require 'spec_helper'

describe 'openstack::client' do

  let :facts do
    { :osfamily => 'Debian', :operatingsystem => 'Ubuntu' }
  end

  describe 'with default params' do
    it { should contain_class('ceilometer::client') }
    it { should contain_class('cinder::client') }
    it { should contain_class('glance::client') }
    it { should contain_class('keystone::client') }
    it { should contain_class('nova::client') }
    it { should contain_class('neutron::client') }
  end

  describe 'without ceilometer' do
    let (:params) { {:ceilometer => false }}
    it { should_not contain_class('ceilometer::client') }
  end

  describe 'without cinder' do
    let (:params) { {:cinder => false }}
    it { should_not contain_class('cinder::client') }
  end

  describe 'without glance' do
    let (:params) { {:glance => false }}
    it { should_not contain_class('glance::client') }
  end

  describe 'without keystone' do
    let (:params) { {:keystone => false }}
    it { should_not contain_class('keystone::client') }
  end

  describe 'without nova' do
    let (:params) { {:nova => false }}
    it { should_not contain_class('nova::client') }
  end

  describe 'without neutron' do
    let (:params) { {:neutron => false }}
    it { should_not contain_class('neutron::client') }
  end
end
