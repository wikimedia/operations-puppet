require 'spec_helper'

describe 'openstack::keystone' do

  # set the parameters that absolutely must be set for the class to even compile
  let :required_params do
    {
      :admin_token            => 'token',
      :db_password            => 'pass',
      :admin_password         => 'pass',
      :glance_user_password   => 'pass',
      :nova_user_password     => 'pass',
      :cinder_user_password   => 'pass',
      :neutron_user_password  => 'pass',
      :public_address         => '127.0.0.1',
      :db_host                => '127.0.0.1',
      :admin_email            => 'root@localhost'
    }
  end

  # set the class parameters to only be those that are required
  let :params do
    required_params
  end

  let :facts do
    { :osfamily => 'Debian', :operatingsystem => 'Ubuntu' }
  end

  describe 'with only required params (and defaults for everything else)' do

    it 'should configure keystone and all default endpoints' do
      should contain_class('keystone').with(
        :verbose        => false,
        :debug          => false,
        :bind_host      => '0.0.0.0',
        :idle_timeout   => '200',
        :catalog_type   => 'sql',
        :admin_token    => 'token',
        :token_format   => 'PKI',
        :enabled        => true,
        :token_driver   => 'keystone.token.backends.sql.Token',
        :sql_connection => 'mysql://keystone:pass@127.0.0.1/keystone',
        :use_syslog     => false,
        :log_facility   => 'LOG_USER'
      )
      [ 'glance', 'cinder', 'neutron' ].each do |type|
        should contain_class("#{type}::keystone::auth").with(
          :password         => params["#{type}_user_password".intern],
          :public_address   => params[:public_address],
          :admin_address    => params[:public_address],
          :internal_address => params[:public_address],
          :region           => 'RegionOne'
        )
      end
      should contain_class('nova::keystone::auth').with(
        :password         => params[:nova_user_password],
        :public_address   => params[:public_address],
        :admin_address    => params[:public_address],
        :internal_address => params[:public_address],
        :region           => 'RegionOne'
      )
    end
  end

  describe 'without nova' do

    let :params do
      required_params.merge(:nova => false)
    end

    it { should_not contain_class('nova::keystone::auth') }

  end

  describe 'without swift' do
    it { should_not contain_class('swift::keystone::auth') }
  end

  describe 'swift' do
    describe 'without password' do
      let :params do
        required_params.merge(:swift => true)
      end
      it 'should fail when the password is not set' do
        expect do
          subject
        end.to raise_error(Puppet::Error)
      end
    end
    describe 'with password' do
      let :params do
        required_params.merge(:swift => true, :swift_user_password => 'dude')
      end
      it do
        should contain_class('swift::keystone::auth').with(
          :password => 'dude',
          :address  => '127.0.0.1',
          :region   => 'RegionOne'
        )
      end
    end
  end

  describe 'without heat' do
    it { should_not contain_class('heat::keystone::auth') }
  end

  describe 'heat' do
    describe 'without password' do
      let :params do
        required_params.merge(:heat => true)
      end
      it 'should fail when the password is not set' do
        expect do
          subject
        end.to raise_error(Puppet::Error)
      end
    end
    describe 'with password' do
      let :params do
        required_params.merge(:heat => true, :heat_user_password => 'dude')
      end
      it do
        should contain_class('heat::keystone::auth').with(
          :password        => 'dude',
          :public_address  => '127.0.0.1',
          :region          => 'RegionOne'
        )
      end
    end
  end

  describe 'without heat_cfn' do
    it { should_not contain_class('heat::keystone::auth_cfn') }
  end

  describe 'heat_cfn' do
    describe 'without password' do
      let :params do
        required_params.merge(:heat_cfn => true)
      end
      it 'should fail when the password is not set' do
        expect do
          subject
        end.to raise_error(Puppet::Error)
      end
    end
    describe 'with password' do
      let :params do
        required_params.merge(:heat_cfn => true, :heat_cfn_user_password => 'dude')
      end
      it do
        should contain_class('heat::keystone::auth_cfn').with(
          :password        => 'dude',
          :public_address  => '127.0.0.1',
          :region          => 'RegionOne'
        )
      end
    end
  end

  describe 'when configuring mysql with SSL' do
    let :params do
      required_params.merge(
        :db_ssl    => true,
        :db_ssl_ca => '/etc/mysql/ca.pem'
      )
    end

    it 'should configure mysql properly' do
      should contain_class('keystone').with(
        :sql_connection => 'mysql://keystone:pass@127.0.0.1/keystone?ssl_ca=/etc/mysql/ca.pem'
      )
    end
  end

  describe 'with custom syslog settings' do
    let :params do
      required_params.merge(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end

    it 'should set parameters in included classes' do
      should contain_class('keystone').with(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
  end
end
