# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'profile::java' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      if facts[:os]['release']['major'].to_i > 9
        let(:package) { 'openjdk-11-jdk' }
      else
        let(:package) { 'openjdk-8-jdk' }
      end

      context 'with role unset' do
        it { is_expected.to contain_package(package) }
        it { is_expected.to compile.with_all_deps }
      end

      context 'with role set' do
        let(:node_params) {{ '_role' => 'analytics_cluster/hadoop/standby' }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('openjdk-8-jdk') }
        it { is_expected.not_to contain_package('openjdk-11-jdk') }
      end
    end
  end
end
