require 'spec_helper'

describe 'openstack::glance' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  let :params do
    {
      :user_password => 'glance_user_pass',
      :db_password   => 'glance_db_pass',
      :keystone_host => '127.0.1.1'
    }
  end

  describe 'with only required parameters' do
    it 'should configure with applicable defaults' do
      should contain_class('glance::api').with(
        :verbose           => false,
        :debug             => false,
        :registry_host     => '0.0.0.0',
        :bind_host         => '0.0.0.0',
        :auth_type         => 'keystone',
        :auth_port         => '35357',
        :auth_host         => '127.0.1.1',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_user_pass',
        :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance',
        :sql_idle_timeout  => '3600',
        :use_syslog        => false,
        :log_facility      => 'LOG_USER',
        :enabled           => true
      )
      should contain_class('glance::registry').with(
        :verbose           => false,
        :debug             => false,
        :bind_host         => '0.0.0.0',
        :auth_host         => '127.0.1.1',
        :auth_port         => '35357',
        :auth_type         => 'keystone',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_user_pass',
        :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance',
        :sql_idle_timeout  => '3600',
        :use_syslog        => false,
        :log_facility      => 'LOG_USER',
        :enabled           => true
      )
      should contain_class('glance::backend::file')
    end
  end

  describe 'with an invalid db_type' do
    before do
      params.merge!(:db_type => 'sqlite' )
    end
    it 'should fail' do
      expect { subject }.to raise_error(Puppet::Error, /db_type sqlite is not supported/)
    end
  end

  describe 'with an invalid backend' do
    before do
      params.merge!(:backend => 'ceph')
    end
    it 'should fail' do
      expect { subject }.to raise_error(Puppet::Error, /Unsupported backend ceph/)
    end
  end

  describe 'when configuring swift as the backend' do

    before do
      params.merge!({
        :backend => 'swift',
        :swift_store_user => 'dan',
        :swift_store_key  => '123'
      })
    end

    it 'should configure swift as the backend' do
      should_not contain_class('glance::backend::file')

      should contain_class('glance::backend::swift').with(
        :swift_store_user                    => 'dan',
        :swift_store_key                     => '123',
        :swift_store_auth_address            => 'http://127.0.0.1:5000/v2.0/',
        :swift_store_create_container_on_put => true
      )
    end

    describe 'user key must be set' do
      before do
        params.delete(:swift_store_key)
      end
      it 'should fail' do
        expect do
          subject
        end.to raise_error(Puppet::Error, /swift_store_key must be set when configuring swift/)
      end
    end
    describe 'user name must be set' do
      before do
        params.delete(:swift_store_user)
      end
      it 'should fail' do
        expect do
          subject
        end.to raise_error(Puppet::Error, /swift_store_user must be set when configuring swift/)
      end
    end
  end

  describe 'when configuring rbd as the backend' do

    before do
      params.merge!({
        :backend         => 'rbd',
        :rbd_store_user  => 'don',
        :rbd_store_pool  => 'images'
      })
    end

    it 'should configure rbd as the backend' do
      should_not contain_class('glance::backend::file')

      should_not contain_class('glance::backend::swift')

      should contain_class('glance::backend::rbd').with(
        :rbd_store_user => 'don',
        :rbd_store_pool => 'images'
      )
    end
  end

  describe 'when configuring mysql with SSL' do
    before do
      params.merge!({
        :db_ssl    => true,
        :db_ssl_ca => '/etc/mysql/ca.pem'
      })
    end

    it 'should configure mysql properly' do
      should contain_class('glance::registry').with(
        :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance?ssl_ca=/etc/mysql/ca.pem'
      )
    end
  end

  describe 'with custom syslog settings' do
    before do
      params.merge!({
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      })
    end

    it 'should set parameters in included classes' do
      should contain_class('glance::api').with(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )

      should contain_class('glance::registry').with(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
  end
end
