require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'base::puppet' do
  let(:pre_condition) {
    [
      'class passwords::puppet::database {}',
      'include apt'
    ]
  }
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts}
      it { should compile }

      context 'when auto_puppetmaster_switching is enabled' do
        context 'on labs' do
          let(:node_params) { { :realm => 'labs' } }
          it { should compile }
          context 'on a standalone puppetmaster' do
            let(:pre_condition) {
              super().concat(
                [
                  'class role::puppetmaster::standalone {}',
                  'require role::puppetmaster::standalone'
                ]
              )
            }
            it 'should fail' do
              should compile.and_raise_error(/should only be applied on puppet clients/)
            end
          end
        end
        context 'on other realms' do
          let(:node_params) {{:realm => 'some_realm'}}
          it 'auto_puppetmaster_switching must not be enableable' do
            should compile.and_raise_error(/auto_puppetmaster_switching should never.*/)
          end
        end
      end
    end
  end
end
