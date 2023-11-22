# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'interface::routing_table' do
  let(:title) { 'dummy-table' }
  let(:params) do
    { number: 123 }
  end

  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "defaults" do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/iproute2/rt_tables.d/dummy-table.conf')
            .with_ensure('file')
            .with_content("123 dummy-table\n")
        end
      end
    end
  end
end
