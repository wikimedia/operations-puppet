require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::timer::job' do
  mock = <<-MOCK
      define monitoring::service(
             $ensure, $description, $check_command, $contact_group, $retries,
             $critical, $event_handler, $check_interval, $retry_interval,
             $notes_url
      ) {}
  MOCK
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { mock }
      let(:title) { 'dummy-test' }
      context "with logging" do
        let(:params) {
          {
            description: 'Some description',
            command: '/bin/true',
            interval: {start: 'OnCalendar', interval: 'Mon,Tue *-*-* 00:00:00'},
            user: 'root',
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_systemd__unit('dummy-test.service')
            .with_ensure('present')
            .with_content(/Description=Some description/)
        end
        it do
          is_expected.to contain_systemd__syslog('dummy-test')
            .with_base_dir('/var/log')
            .with_log_filename('syslog.log')
        end
      end
      context "without logging" do
        let(:params) {
          {
            description: 'Some description',
            command: '/bin/true',
            interval: {start: 'OnCalendar', interval: 'Mon,Tue *-*-* 00:00:00'},
            user: 'root',
            logging_enabled: false,
          }
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_systemd__syslog('dummy-test') }
      end
      context "with several intervals" do
        let(:params) {
          {
            description: 'Some description',
            command: '/bin/true',
            interval: [{start: 'OnCalendar', interval: 'Mon,Tue *-*-* 00:00:00'},
                       {start: 'OnCalendar', interval: 'Wed,Thu *-*-* 00:00:00'},],
          user: 'root',
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_systemd__unit('dummy-test.service')
            .with_ensure('present')
            .with_content(/Description=Some description/)
        end
        it { is_expected.not_to contain_exec('systemd start for dummy-test.service') }
      end
      context "with OnUnitInactiveSec" do
        let(:params) {
          {
            description: 'Some description',
            command: '/bin/true',
            interval: [{start: 'OnUnitInactiveSec', interval: '3600s'},],
            user: 'root',
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_systemd__timer('dummy-test')
          # We didn't provide any other kind of interval, so an OnActiveSec should be generated.
          intervals = catalogue.resource('systemd::timer', 'dummy-test').send(:parameters)[:timer_intervals]
          expect(intervals).to include(include('start' => 'OnActiveSec'))
        end
      end
      context 'with splay' do
        let(:params) {
          {
            description: 'Timer with splay set',
            command: '/bin/true',
            interval: {start: 'OnCalendar', interval: 'Daily'},
            user: 'root',
            splay: 42,
          }
        }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_systemd__timer('dummy-test')
            .with_splay(42)
        end
      end
    end
  end
end
