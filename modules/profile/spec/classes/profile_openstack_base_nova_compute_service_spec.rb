require_relative '../../../../rake_modules/spec_helper'

describe 'profile::openstack::base::nova::compute::service' do
  let(:pre_condition) do
    [
      'class { "::apt": }',
      'class{ \'openstack::nova::common\':
          version => \'victoria\',
          region => \'eqiad1-r\',
          db_user => \'dummydbuser\',
          db_pass => \'dummydbpass\',
          db_host => \'dummydbhost\',
          db_name => \'dummydbname\',
          db_name_api => \'dummydbnameapi\',
          openstack_controllers => [\'controller01\'],
          rabbitmq_nodes => [\'rabbit01\'],
          keystone_api_fqdn => \'dummy.api.fqdn\',
          scheduler_filters => [\'filter1\'],
          ldap_user_pass => \'dummypass\',
          rabbit_user => \'dummyuser\',
          rabbit_pass => \'dummypass\',
          metadata_proxy_shared_secret => \'dummysecret\',
          compute_workers => 2,
          metadata_listen_port => 4242,
          osapi_compute_listen_port => 4242,
          is_control_node => false,
      }',
      'class { \'prometheus::node_exporter\': }',
    ]
  end
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) {{
        'version' => 'victoria',
        'instance_dev' => 'thinvirt',
        'network_flat_interface' => 'eno50.1105',
        'network_flat_tagged_base_interface' => 'eno50',
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
    end
  end
end
