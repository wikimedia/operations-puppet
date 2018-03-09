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
  context 'when using an valid time spec' do
    let(:pre_condition) {
'systemd::service { "dummy.service":
                  content => "",
                  service_params => { "provider" => "systemd" }
}'}
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '3 hour 10 sec'}]
      }
    }
    it { is_expected.to compile.with_all_deps }
  end
  context 'when referring to an inexistent service' do
    let(:params) {
      {
        :timer_intervals => [{'start' => 'OnBootSec', 'interval' => '3 hour 10 sec'}]
      }
    }
  end
end
