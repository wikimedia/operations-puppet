require_relative '../../../../rake_modules/spec_helper'

describe 'nrpe::check', :type => :define do
  on_supported_os(WMFConfig.test_on(9, 9)).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts.merge({ realm: 'production' }) }
      let(:title) { 'something' }
      let(:params) { { command: '/usr/local/bin/mycommand -i this -o that' } }

      context 'with nrpe class not defined' do
        it { is_expected.not_to contain_file('/etc/nagios/nrpe.d/something.cfg') }
      end

      context 'with nrpe class defined' do
        let(:pre_condition) { "include nrpe" }

        it { is_expected.to contain_file('/etc/nagios/nrpe.d/something.cfg') }
      end

      context 'with ensure absent' do
        let(:params) { super().merge(ensure: 'absent') }
        it { is_expected.not_to contain_file('/etc/nagios/nrpe.d/something.cfg') }
      end
    end
  end
end
