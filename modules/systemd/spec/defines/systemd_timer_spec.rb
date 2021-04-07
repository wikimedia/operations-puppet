require_relative '../../../../rake_modules/spec_helper'

# The spec test fails on mac osx due to a missing /usr/bin/systemd-analyze
# you can use the following script to fix this, i created this in
# /usr/local/bin and thnen symlinked to /usr/bin which requires one to
# temporarily disable System Integrity Protocol from Recovery Mode
# https://phabricator.wikimedia.org/P13043

describe 'systemd::timer' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:title) { 'dummy'}
      let(:pre_condition) do
        'systemd::unit { "dummy.service": content => ""}'
      end

      context 'when using an invalid time spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '10 bananas'}]
          }
        }
        it { is_expected.to compile.and_raise_error(/bananas/) }
      end
      context 'when using a valid time spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '3 hour 10 sec'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using an invalid calendar spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mooby 11/11/2911 contantly'}]
          }
        }
        it { is_expected.to compile.and_raise_error(/Mooby/) }
      end
      context 'when using a valid calendar spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* 00:00:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using a valid everyday calendar spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using a valid calendar (with repetition) spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* 00/4:00:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using a valid everyday calendar (with repetition) spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* 00/4:00:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using a valid hourly calendar spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* *:20:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using a valid everyday hourly calendar spec' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* *:20:00'}]
          }
        }
        it { is_expected.to compile.with_all_deps }
      end
      context 'when using splay' do
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Daily' }],
            :splay => 42,
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_systemd__service('dummy')
            .with_unit_type('timer')
          is_expected.to contain_file('/lib/systemd/system/dummy.timer')
            .with_content(/^RandomizedDelaySec=42$/)
        end
      end
      context 'when referring to an inexistent unit' do
        let(:pre_condition) {}
        let(:params) {
          {
            :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '3 hour 10 sec'}]
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
end
