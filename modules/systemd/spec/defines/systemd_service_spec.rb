require 'spec_helper'
describe 'systemd::service' do
  let(:facts) { {:initsystem => 'systemd' } }
  let(:title) { 'dummy'}
  context 'when using an invalid unit type' do
    let(:params) {
      {
        :content => 'test',
        :unit_type => 'invalid'
      }
    }
    it {
      is_expected.to compile.and_raise_error(/parameter 'unit_type' expects a match for Systemd::Unit_type/)
    }
  end
  context 'when using defaults' do
    let(:params) {
      {
        :content => 'test'
      }
    }
    it {
      is_expected.to contain_service('dummy')
                       .with_ensure('running')
                       .with_enable('true')
    }
    it {
      is_expected.to contain_systemd__unit('dummy')
                       .with_ensure('present')
                       .with_content('test')
                       .with_override(false)
                       .with_restart(false)
    }
  end
  context 'when defining all parameters' do
    let(:params) {
      {
        :content => 'test',
        :unit_type => 'mount',
        :ensure   => 'absent',
        :restart  => true,
        :override => true,
        :service_params => {'path' => '/bar'}
      }
    }
    it {
      is_expected.to contain_service('dummy.mount')
                       .with_enable(false)
                       .with_ensure('stopped')
                       .with_path('/bar')
    }
    it {
      is_expected.to contain_systemd__unit('dummy.mount')
                       .with_ensure('absent')
                       .with_content('test')
                       .with_override(true)
                       .with_restart(true)
    }
  end
end
