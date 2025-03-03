# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::path' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:title) { 'dummy'}
      let(:pre_condition) do
        'systemd::unit { "dummy.service": content => ""}'
      end
      context 'when monitor_type is missing' do
        let(:params) {
          {
            :monitor_path => '/test'
          }
        }
        it { is_expected.to raise_error(Puppet::Error) }
      end
      context 'when using an invalid monitor_type' do
        let(:params) {
          {
            :monitor_path => '/test',
            :monitor_type => 'BatExists'
          }
        }
        it { is_expected.to compile.and_raise_error(/BatExists/) }
      end
      context 'when using a valid monitor_type' do
        let(:params) {
          {
            :monitor_path => '/test',
            :monitor_type => 'PathExists'
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when $monitor_path is not defined' do
        let(:params) {
          {
            :monitor_type => 'PathExists'
          }
        }
        it { is_expected.to raise_error(Puppet::Error) }
      end
      context 'when $unit has wrong name' do
        let(:params) {
          {
            :monitor_path => '/test',
            :monitor_type => 'PathExists',
            :unit         => 'dummy.timer'
          }
        }
        it { is_expected.to raise_error(Puppet::Error) }
      end
    end
    context 'when referring to non-existent unit' do
      let(:title) { 'dummy' }
      let(:pre_condition) {}
      let(:params) {
        {
          :monitor_path => '/test',
          :monitor_type => 'PathExists'
        }
      }
      it do
        is_expected.to compile.and_raise_error(
          /Could not find resource 'Systemd::Unit\[dummy.service\]'/
        )
      end
    end
  end
end
