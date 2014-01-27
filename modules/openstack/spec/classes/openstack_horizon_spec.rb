require 'spec_helper'

describe 'openstack::horizon' do

  let :required_params do
    { :secret_key => 'super_secret' }
  end

  let :params do
    required_params
  end

  let :facts do
    {
      :osfamily       => 'Redhat',
      :memorysize     => '1GB',
      :processorcount => '1',
      :concat_basedir => '/tmp',
      :operatingsystemrelease => '5'
    }
  end

  it 'should configure horizon and memcache using default parameters and secret key' do
    should contain_class('memcached').with(
      :listen_ip => '127.0.0.1',
      :tcp_port  => '11211',
      :udp_port  => '11211'
    )
    should contain_class('horizon').with(
      :cache_server_ip       => '127.0.0.1',
      :cache_server_port     => '11211',
      :secret_key            => 'super_secret',
      :horizon_app_links     => false,
      :keystone_host         => '127.0.0.1',
      :keystone_scheme       => 'http',
      :keystone_default_role => '_member_',
      :django_debug          => 'False',
      :api_result_limit      => 1000
    )
  end

  context 'when memcached is disabled' do
    let :params do
      required_params.merge(
        :configure_memcached => false
      )
    end
    it 'should configure horizon without memcached using default parameters and secret key' do
      should_not contain_class('memcached')
      should contain_class('horizon').with(
        :cache_server_ip       => '127.0.0.1',
        :cache_server_port     => '11211',
        :secret_key            => 'super_secret',
        :horizon_app_links     => false,
        :keystone_host         => '127.0.0.1',
        :keystone_scheme       => 'http',
        :keystone_default_role => '_member_',
        :django_debug          => 'False',
        :api_result_limit      => 1000
      )
    end
  end

  context 'when memcached listen ip is overridden' do
    let :params do
      required_params.merge(
        :configure_memcached => true,
        :memcached_listen_ip => '10.10.10.10'
      )
    end
    it 'should override params for memcached' do
      should contain_class('memcached').with(
        :listen_ip => '10.10.10.10'
      )
    end
  end
end
