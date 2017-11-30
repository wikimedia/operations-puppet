require 'spec_helper'

# Adding a test on the exposition of Puppet CA cert here to make it explicit
# that clients of base::expose_puppet_certs most probably need this cert to be
# exposed as well
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'profile::base::certificates' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it 'should expose Puppet CA certificate' do
        should contain_file('/usr/local/share/ca-certificates/Puppet_Internal_CA.crt')
                 .with({ 'ensure' => 'present' })
      end
    end
  end
end
