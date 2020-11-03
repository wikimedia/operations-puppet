require_relative '../../../../rake_modules/spec_helper'

describe 'profile::base::certificates' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it 'should expose Puppet CA certificate' do
        should contain_file('/usr/local/share/ca-certificates/Puppet_Internal_CA.crt')
                 .with({ 'ensure' => 'present' })
      end
    end
  end
end
