require_relative '../../../../rake_modules/spec_helper'

describe 'nrpe::monitor_service', :type => :define do
  on_supported_os(WMFConfig.test_on(9, 9)).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge({ realm: 'production' }) }
      let(:title) { 'something' }
      let(:params) do
        {
          ensure:        'present',
          description:   'this is a description',
          contact_group: 'none',
          nrpe_command:  '/usr/local/bin/mycommand -i this -o that',
          critical:      false,
          timeout:       42,
          notes_url:     'https://wikitech.wikimedia.org/wiki/Monitoring'
        }
      end
      let(:pre_condition) do
        'class profile::base { $notifications_enabled = "1"}
        include profile::base'
      end

      context 'with ensure present' do
        it do
          is_expected.to contain_nrpe__check('check_something').with(
            command: '/usr/local/bin/mycommand -i this -o that',
            ensure:  'present'
          )
        end
        it do
          is_expected.to contain_monitoring__service('something').with(
            description:   'this is a description',
            contact_group: 'none',
            retries:       3,
            ensure:        'present',
            check_command: 'nrpe_check!check_something!42',
            critical:      false,
            notes_url:     'https://wikitech.wikimedia.org/wiki/Monitoring'
          )
        end
      end

      context 'with ensure present, description missing' do
        let(:params) { super().merge(description: nil) }

        it { is_expected.to compile }
      end

      context 'with ensure present, nrpe_command missing' do
        let(:params) { super().merge(nrpe_command: nil) }

        it { is_expected.to compile }
      end

      context 'with ensure absent, nrpe_command missing' do
        let(:params) { super().merge(nrpe_command: nil, ensure: 'absent') }

        it { is_expected.to compile }
        it { is_expected.to contain_nrpe__check('check_something').with_ensure('absent') }
        it { is_expected.to contain_monitoring__service('something').with_ensure('absent') }
      end

      context 'with ensure absent, description missing' do
        let(:params) { super().merge(description: nil, ensure: 'absent') }

        it { is_expected.to compile }
        it { is_expected.to contain_nrpe__check('check_something').with_ensure('absent') }
        it { is_expected.to contain_monitoring__service('something').with_ensure('absent') }
      end
    end
  end
end
