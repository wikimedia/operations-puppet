require 'spec_helper'

# Adding a test on the exposition of Puppet CA cert here to make it explicit
# that clients of base::expose_puppet_certs most probably need this cert to be
# exposed as well
describe 'profile::base::certificates' do
    it 'should exposes Puppet CA certificate' do
        should contain_file('/usr/local/share/ca-certificates/Puppet_Internal_CA.crt')
            .with({ 'ensure' => 'present' })
    end
end
