require 'spec_helper'

describe 'openstack::cinder::storage' do

  let :params do
    {
      :sql_connection  => 'mysql://a:b:c:d',
      :rabbit_password => 'rabpass'
    }
  end

  let :facts do
    { :osfamily => 'Redhat' }
  end

  it 'should configure cinder and cinder::volume using defaults and required parameters' do
    should contain_class('cinder').with(
      :sql_connection      => params[:sql_connection],
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

  describe 'with a volume driver other than iscsi' do
    before do
      params.merge!(
        :volume_driver => 'netapp'
      )
    end
    it { should_not contain_class('cinder::volume::iscsi') }
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

  describe 'when setting up test volumes for rbd' do
    before do
      params.merge!(
          :volume_driver   => 'rbd',
          :rbd_user        => 'rbd',
          :rbd_pool        => 'rbd_pool',
          :rbd_secret_uuid => 'secret'
      )
    end

    it { should contain_class('cinder::volume::rbd').with(
                    :rbd_user => 'rbd',
                    :rbd_pool => 'rbd_pool',
                    :rbd_secret_uuid => 'secret'
                ) }


  end

  describe 'with custom syslog parameters' do
    before do
      params.merge!(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end

    it { should contain_class('cinder').with(
      :use_syslog   => true,
      :log_facility => 'LOG_LOCAL0'
    ) }
  end
end
