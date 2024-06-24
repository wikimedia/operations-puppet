require_relative '../../../../rake_modules/spec_helper'

describe 'profile::openstack::base::nova::compute::service' do
  let(:pre_condition) do
    [
      'class { "::apt": }',
      'class { \'ceph::common\':
          home_dir => \'/var/lib/ceph/\',
          ceph_repository_component => \'something\',
      }',
      'class { \'ceph::config\':
          enable_libvirt_rbd => true,
          enable_v2_messenger => true,
          mon_hosts => {
            "monhost01.local" => {
              "public" => {
                "addr" => "127.0.10.1",
              },
            },
            "monhost02.local" => {
              "public" => {
                "addr" => "127.0.10.2",
              },
            },
          },
          cluster_networks => [\'192.168.4.0/24\'],
          public_networks => [\'10.192.20.0/24\'],
          fsid => \'dummyfsid-17bc-44dc-9aeb-1d044c9bba9e\',
       }',
      'class{ \'openstack::nova::common\':
          version => \'bobcat\',
          region => \'eqiad1-r\',
          db_user => \'dummydbuser\',
          db_pass => \'dummydbpass\',
          db_host => \'dummydbhost\',
          db_name => \'dummydbname\',
          db_name_api => \'dummydbnameapi\',
          memcached_nodes => [\'controller01\'],
          rabbitmq_nodes => [\'rabbit01\'],
          keystone_fqdn => \'dummy.api.fqdn\',
          scheduler_filters => [\'filter1\'],
          ldap_user_pass => \'dummypass\',
          rabbit_user => \'dummyuser\',
          rabbit_pass => \'dummypass\',
          metadata_proxy_shared_secret => \'dummysecret\',
          compute_workers => 2,
          metadata_listen_port => 4242,
          osapi_compute_listen_port => 4242,
          is_control_node => false,
          enforce_policy_scope => true,
          enforce_new_policy_defaults => true,
      }',
      'class { \'prometheus::node_exporter\': }',
    ]
  end
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
          os_facts.merge({
            'interface_primary' => "eno1",
          })
      end
      let(:params) {{
        'version' => 'bobcat',
        'instance_dev' => 'thinvirt',
        'network_flat_interface' => 'eno50.1105',
        'network_flat_interface_vlan' => '1105',
        'all_cloudvirts' => [
            'cloudvirt01', 'cloudvirt02',
        ],
        'libvirt_cpu_model' => 'Haswell-noTSX-IBRS',
      }}
      let(:node_params) {{'_role' => 'sretest'}}
      it 'compiles without errors' do
          is_expected.to compile.with_all_deps
      end
      context "NIC configuration is generated correctly" do
        let(:params) {
          super().merge({
            'network_flat_interface' => 'vlan1105',
            'network_flat_interface_vlan' => '1105',
          })
        }
        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_interface__tagged("vlan1105")
              .with_base_interface("eno1")
              .with_vlan_id("1105")
              .with_method("manual")
              .with_legacy_vlan_naming(false)
        }
      end
    end
  end
end
