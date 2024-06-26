require_relative '../../../../rake_modules/spec_helper'

describe 'cassandra::instance' do
    let(:title) {'foobar'}
    let(:pre_condition) do
      'include cassandra'
    end

    on_supported_os(WMFConfig.test_on).each do |os, facts|
        context "on #{os}" do
            let(:facts) { facts }
            let(:params) do
              {
                cluster_name: 'Test Cluster',
                memory_allocator: 'foobar',
                listen_address: '192.0.2.1',
                native_transport_port: 9043,
                target_version: '3.x',
                seeds: ['192.0.2.1'],
                dc: 'datacenter1',
                rack: 'rack1',
                additional_jvm_opts: [],
                extra_classpath: [],
                logstash_host: 'localhost',
                logstash_port: 11_514,
                start_rpc: true,
                super_username: 'cassandra',
                super_password: 'cassandra',
              }
            end
            describe 'test with default settings' do
               it { is_expected.to compile.with_all_deps }
            end
        end
    end
end
