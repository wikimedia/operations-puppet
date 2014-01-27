require 'spec_helper'

describe 'openstack::neutron' do

  let :facts do
    {:osfamily => 'Redhat'}
  end

  let :params do
    {
      :user_password   => 'q_user_pass',
      :rabbit_password => 'rabbit_pass',
      :db_password     => 'bar'
    }
  end

  context 'install neutron with default settings' do
    before do
      params.delete(:db_password)
    end
    it 'should fail b/c database password is required' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /db password must be set/)
    end
  end
  context 'install neutron with default and database password' do
    it 'should perform default configuration' do
      should contain_class('neutron').with(
        :enabled               => true,
        :bind_host             => '0.0.0.0',
        :rabbit_host           => '127.0.0.1',
        :rabbit_hosts          => false,
        :rabbit_virtual_host   => '/',
        :rabbit_user           => 'rabbit_user',
        :rabbit_password       => 'rabbit_pass',
        :use_syslog            => false,
        :log_facility          => 'LOG_USER',
        :allow_overlapping_ips => false,
        :verbose               => false,
        :debug                 => false
      )
      should contain_class('neutron::server').with(
        :auth_host     => '127.0.0.1',
        :auth_password => 'q_user_pass'
      )
      should contain_class('neutron::plugins::ovs').with(
        :sql_connection      => "mysql://neutron:bar@127.0.0.1/neutron?charset=utf8",
        :tenant_network_type => 'gre'
      )
    end
  end

  context 'when server is disabled' do
    before do
      params.merge!(:enable_server => false)
    end
    it 'should not configure server' do
      should_not contain_class('neutron::server')
      should_not contain_class('neutron::plugins::ovs')
    end
  end

  context 'when ovs agent is enabled with all required params' do
    before do
      params.merge!(
        :enable_ovs_agent => true,
        :bridge_uplinks   => ['br-ex:eth0'],
        :bridge_mappings  => ['default:br-ex'],
        :ovs_local_ip     => '10.0.0.2'
      )
    end
    it { should contain_class('neutron::agents::ovs').with(
      :bridge_uplinks   => ['br-ex:eth0'],
      :bridge_mappings  => ['default:br-ex'],
      :enable_tunneling => true,
      :local_ip         => '10.0.0.2',
      :firewall_driver  => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
    )}
  end

  context 'when dhcp agent is enabled' do
    before do
      params.merge!(:enable_dhcp_agent => true)
    end
    it { should contain_class('neutron::agents::dhcp').with(
      :use_namespaces => true,
      :debug          => false
    ) }
  end

  context 'when l3 agent is enabled' do
    before do
      params.merge!(:enable_l3_agent => true)
    end
    it { should contain_class('neutron::agents::l3').with(
      :use_namespaces => true,
      :debug          => false
    ) }
  end

  context 'when metadata agent is enabled' do
    before do
      params.merge!(
        :enable_metadata_agent => true
      )
    end
    it 'should fail' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /metadata_shared_secret parameter must be set/)
    end
    context 'with a shared secret' do
      before do
        params.merge!(
          :shared_secret => 'foo'
        )
      end
      it { should contain_class('neutron::agents::metadata').with(
        :auth_password  => 'q_user_pass',
        :shared_secret  => 'foo',
        :auth_url       => 'http://localhost:35357/v2.0',
        :metadata_ip    => '127.0.0.1',
        :debug          => false
      ) }
    end
  end

  context 'with custom syslog settings' do
    before do
      params.merge!(
        :use_syslog   => true,
        :log_facility => 'LOG_LOCAL0'
      )
    end
    it { should contain_class('neutron').with(
      :use_syslog   => true,
      :log_facility => 'LOG_LOCAL0'
    ) }
  end

  context 'with invalid db_type' do
    before do
      params.merge!(:db_type => 'foo', :db_password => 'bar')
    end
    it 'should fail' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /Unsupported db type: foo./)
    end
  end

end
