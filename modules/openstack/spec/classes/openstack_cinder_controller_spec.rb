require 'spec_helper'

describe 'openstack::cinder::controller' do

  let :params do
    {
      :db_password      => 'db_password',
      :rabbit_password   => 'rabpass',
      :keystone_password => 'user_pass'
    }
  end

  let :facts do
    { :osfamily => 'Redhat' }
  end

  it 'should configure using the default values' do
    should contain_class('cinder').with(
      :sql_connection      => "mysql://cinder:#{params[:db_password]}@127.0.0.1/cinder?charset=utf8",
      :sql_idle_timeout    => '3600',
      :rpc_backend         => 'cinder.openstack.common.rpc.impl_kombu',
      :rabbit_userid       => 'guest',
      :rabbit_password     => params[:rabbit_password],
      :rabbit_host         => '127.0.0.1',
      :rabbit_port         => '5672',
      :rabbit_hosts        => false,
      :rabbit_virtual_host => '/',
      :package_ensure      => 'present',
      :api_paste_config    => '/etc/cinder/api-paste.ini',
      :use_syslog          => false,
      :log_facility        => 'LOG_USER',
      :debug               => false,
      :verbose             => false
    )
    should contain_class('cinder::api').with(
      :keystone_password       => params[:keystone_password],
      :keystone_enabled        => true,
      :keystone_user           => 'cinder',
      :keystone_auth_host      => 'localhost',
      :keystone_auth_port      => '35357',
      :keystone_auth_protocol  => 'http',
      :service_port            => '5000',
      :package_ensure          => 'present',
      :bind_host               => '0.0.0.0',
      :enabled                 => true
    )
    should contain_class('cinder::scheduler').with(
      :scheduler_driver       => 'cinder.scheduler.simple.SimpleScheduler',
      :package_ensure         => 'present',
      :enabled                => true
    )
  end

  describe 'with custom syslog settings' do
    before do
      params.merge!({
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      })
    end

    it do
      should contain_class('cinder').with(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
  end

  context 'with unsupported db type' do

    before do
      params.merge!({:db_type => 'sqlite'})
    end

    it do
      expect { subject }.to raise_error(Puppet::Error, /Unsupported db_type sqlite/)
    end
  end

end
