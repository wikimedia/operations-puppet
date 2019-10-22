require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'systemd::timer' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge(initsystem: 'systemd') }
      let(:title) { 'dummy'}
      let(:pre_condition) { 'systemd::unit { "dummy.service": content => ""}' }

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
