require 'spec_helper'

describe 'openstack::cinder::all' do

  let :params do
    {
      :db_password      => 'db_password',
      :rabbit_password   => 'rabpass',
      :keystone_password => 'user_pass'
    }
  end

  let :facts do
    { :osfamily => 'Debian' }
  end

  it 'should configure using the default values' do
    should contain_class('cinder').with(
      :sql_connection      => "mysql://cinder:#{params[:db_password]}@127.0.0.1/cinder?charset=utf8",
      :sql_idle_timeout    => '3600',
      :rpc_backend         => 'cinder.openstack.common.rpc.impl_kombu',
      :rabbit_userid       => 'openstack',
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
    should contain_class('cinder::volume').with(
      :package_ensure => 'present',
      :enabled        => true
    )
    should contain_class('cinder::volume::iscsi').with(
      :iscsi_ip_address => '127.0.0.1',
      :volume_group     => 'cinder-volumes'
    )
    should_not contain_class('cinder::setup_test_volume')
  end

  describe 'with manage_volumes set to false' do
    before do
      params.merge!(
        :manage_volumes => false
      )
    end
    it { should_not contain_class('cinder::volume') }
  end

  describe 'with a volume driver other than iscsi' do
    before do
      params.merge!(
        :volume_driver => 'netapp'
      )
    end
    it { should_not contain_class('cinder::volume::iscsi') }
  end

  describe 'with a volume driver other than rbd' do
    before do
      params.merge!(
        :volume_driver => 'netapp'
      )
    end
    it { should_not contain_class('cinder::volume::rbd') }
  end

  describe 'with the rbd volume driver' do
    before do
      params.merge!(
        :volume_driver => 'rbd'
      )
    end
    it { should contain_class('cinder::volume::rbd') }
  end

  describe 'when setting up test volumes for iscsi' do
    before do
      params.merge!(
        :setup_test_volume => true
      )
    end
    it { should contain_class('cinder::setup_test_volume').with(
      :volume_name => 'cinder-volumes'
    )}
    describe 'when volume_group is set' do
      before do
        params.merge!(:volume_group => 'foo')
      end
      it { should contain_class('cinder::setup_test_volume').with(
        :volume_name => 'foo'
      )}
    end
  end

  describe 'with custom syslog settings' do
    before do
      params.merge!(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
    it { should contain_class('cinder').with(
      :use_syslog   => true,
      :log_facility => 'LOG_LOCAL0'
    )}
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
