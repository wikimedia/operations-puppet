require 'spec_helper'

describe 'systemd::timer' do
  let(:facts) { {:initsystem => 'systemd' } }
  let(:title) { 'dummy'}
  context 'when using an invalid time spec' do
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '10 bananas'}]
      }
    }
    it { is_expected.to compile.and_raise_error(/bananas/) }
  end
  context 'when using a valid time spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
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
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* 00:00:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when using a valid everyday calendar spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* 00:00:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when using a valid calendar (with repetition) spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* 00/4:00:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when using a valid everyday calendar (with repetition) spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* 00/4:00:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when using a valid hourly calendar spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => 'Mon,Tue *-*-* *:20:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when using a valid everyday hourly calendar spec' do
    let(:pre_condition) {
'systemd::unit { "dummy.service":
                  content => "",
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnCalendar', 'interval' => '*-*-* *:20:00'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when referring to an inexistent unit' do
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '3 hour 10 sec'}]
      }
    }
    it { is_expected.to compile.and_raise_error(/Could not retrieve dependency/) }
  end
end
