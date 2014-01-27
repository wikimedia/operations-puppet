require 'spec_helper'

describe 'openstack::test_file' do
  it do
    should contain_file('/tmp/test_nova.sh').with_mode('0751')
    should_not contain_file('/tmp/test_nova.sh').with_content(/add-floating-ip/)
    should contain_file('/tmp/test_nova.sh').with_content(/floatingip-create/)
  end
end
