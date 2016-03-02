require 'spec_helper'

# This test could be moved to the `role` module, but all I am interested here
# is the parts that are related to k8s, so I'm keeping it here for the moment.
#
# `role::toollabs::k8s::master` has too many dependencies to be testable under
# reasonable efforts. This test can still be run by commenting out everything
# not related to k8s in `role::toollabs::k8s::master`

describe 'role::toollabs::k8s::master', :type => :class do
  let(:facts) { {:fqdn => 'host.example.net'} }

  context 'with systemd as init' do
    let(:facts) { {:initsystem => 'systemd'} }

    it 'should contain Kubernetes apiserver' do
      pending 'role::toollabs::k8s::master should be refactored to be actually testable'
      should contain_class('k8s::apiserver')
    end
    it 'should contain Kubernetes scheduler' do
      pending 'role::toollabs::k8s::master should be refactored to be actually testable'
      should contain_class('k8s::scheduler')
    end
    it 'should contain Kubernetes controller' do
      pending 'role::toollabs::k8s::master should be refactored to be actually testable'
      should contain_class('k8s::controller')
    end

  end

end
