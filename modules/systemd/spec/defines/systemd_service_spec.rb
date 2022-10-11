require_relative '../../../../rake_modules/spec_helper'

describe 'systemd::service' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'dummy'}
      let(:params) { { content: 'test' } }
      context 'when using an invalid unit type' do
        let(:params) { super().merge(unit_type: 'invalid') }
        it {
          is_expected.to compile.and_raise_error(/parameter 'unit_type' expects a match for Systemd::Unit_type/)
        }
      end
      context 'when using defaults' do
        it { is_expected.to contain_service('dummy').with_ensure('running') .with_enable('true') }
        it do
          is_expected.to contain_systemd__unit('dummy')
            .with_ensure('present')
            .with_content('test')
            .with_override(false)
            .with_override_filename('puppet-override.conf')
            .with_restart(false)
        end
      end
      context 'when defining all parameters' do
        let(:params) {
          {
            :content => 'test',
            :unit_type => 'mount',
            :ensure   => 'absent',
            :restart  => true,
            :override => true,
            :override_filename => 'myoverride.conf',
            :service_params => {'path' => '/bar'}
          }
        }
        it do
          is_expected.to contain_service('dummy.mount')
            .with_enable(false)
            .with_ensure('stopped')
            .with_path('/bar')
        end
        it do
          is_expected.to contain_systemd__unit('dummy.mount')
            .with_ensure('absent')
            .with_content('test')
            .with_override(true)
            .with_override_filename('myoverride.conf')
            .with_restart(true)
        end
      end
    end
  end
end
