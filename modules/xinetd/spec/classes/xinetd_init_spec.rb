require 'spec_helper'

describe 'xinetd' do
  it {
    should contain_package('xinetd')
    should contain_file('/etc/xinetd.conf')
    should contain_service('xinetd').with_restart('/etc/init.d/xinetd reload')
  }
end
