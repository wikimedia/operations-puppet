# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::spicerack' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      context "production server" do
        let(:node_params) {{ '_role' => 'cluster/management' }}
        describe 'test compilation with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file('/etc/spicerack/kafka/config.yaml') }
        end
      end
      context "cloud production server" do
        let(:node_params) {{ '_role' => 'cluster/cloud_management' }}
        describe 'test compilation with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_file('/etc/spicerack/kafka/config.yaml') }
        end
      end
    end
  end
end
