# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
# To run the tests you can:
##  Run the utils/run_ci_tests.sh script (recommended, though a bit slow)
##  Setup rbenv or similar, and use bundle rake (see https://wikitech.wikimedia.org/wiki/Puppet_coding/testing)

describe 'profile::wmcs::services::toolsdb_replica_cnf' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      }) }
      it {
        is_expected.to compile.with_all_deps
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
