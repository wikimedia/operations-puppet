require 'spec_helper'

describe 'k8s::infrastructure_config', :type => :class do

  it 'should containt kubeconfig file with correct certificate path' do
    should contain_file('/etc/kubernetes/kubeconfig')
               .with({ 'ensure' => 'present' })
               .with_content(/certificate-authority: \/etc\/ssl\/certs\/Puppet_Internal_CA.pem/)

  end

end
