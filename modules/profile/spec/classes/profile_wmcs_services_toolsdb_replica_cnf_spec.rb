# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
# To run the tests you can:
##  Run the utils/run_ci_tests.sh script (recommended, though a bit slow)
##  Setup rbenv or similar, and use bundle rake (see https://wikitech.wikimedia.org/wiki/Puppet_coding/testing)

describe 'profile::wmcs::services::toolsdb_replica_cnf' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    ['tools', 'toolsbeta'].each do |project|
      context "on #{os} in project #{project}" do
        let(:facts) { facts.merge({
          'fqdn' => 'dummyhost1',
          'wmcs_project' => project,
        }) }
        it {
          is_expected.to compile.with_all_deps
        }
        it {
          is_expected.to contain_file('/etc/replica_cnf_config.yaml')
            .with_content(/ToolforgeToolFileBackend/)
            .with_content(/ToolforgeUserFileBackend/)
            .with_content(/ToolforgeToolEnvvarsBackend/)
            .without_content(/PawsUserFileBackend/)
        }
      end
    end

    context "on #{os} in project paws" do
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
        'wmcs_project' => 'paws',
      }) }
      it {
        is_expected.to compile.with_all_deps
      }
      it {
        is_expected.to contain_file('/etc/replica_cnf_config.yaml')
          .with_content(/PawsUserFileBackend/)
          .without_content(/Toolforge\w+Backend/)
      }
    end

    context "on #{os} in an unsupported project" do
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
        'wmcs_project' => 'otherproject',
      }) }
      it {
        is_expected.to compile.and_raise_error(/Only tools, toolsbeta or paws are supported/)
      }

      #  # Example of more complex test
      #  # the 'contain_*' and 'with_*' are generated on the fly, the first for defines, the second for parameters
      #  # for example, 'is_expected.to contain_somerandom__define('somename')' will check that there's a:
      #  #       somerandom::define {'somename': }
      #  #   entry in the code, if you add `.with_some_parameter_name('some_value')` will check for something like:
      #  #       somerandom::define {'somename':
      #  #           'some_parameter_name' => 'some_value',
      #  #       }
      #  context "when storage_retention_size is passed" do
      #    let(:params) { super().merge({
      #      'storage_retention_size' => '50GB'
      #    }) }
      #    it { is_expected.to contain_prometheus__server('labs').with_storage_retention_size('50GB') }
      #  end
    end
  end
end
