require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'systemd::timer::job' do
    mock = <<-MOCK
      define monitoring::service(
             $ensure, $description, $check_command, $contact_group, $retries,
             $critical, $event_handler, $check_interval, $retry_interval,
             $notes_url
      ) {}
    MOCK
    on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) do
        facts.merge({initsystem: 'systemd'})
      end
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
       it {
         is_expected.to contain_systemd__unit('dummy-test.service')
                          .with_ensure('present')
                          .with_content(/Description=Some description/)
        }
       it { is_expected.to contain_systemd__syslog('dummy-test')
                             .with_base_dir('/var/log')
                             .with_log_filename('syslog.log')
       }
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
    end
  end
end
