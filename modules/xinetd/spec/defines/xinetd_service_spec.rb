require 'spec_helper'

describe 'xinetd::service' do
  let :default_params do
    {
      'port'   => '80',
      'server' => 'httpd'
    }
  end

  let :title do
    "httpd"
  end

  describe 'with default ensure' do
    let :params do
      default_params
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('present')
    }
  end

  describe 'with ensure=present' do
    let :params do
      default_params.merge({'ensure' => 'present'})
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('present')
    }
  end

  describe 'with ensure=absent' do
    let :params do
      default_params.merge({'ensure' => 'absent'})
    end
    it {
      should contain_file('/etc/xinetd.d/httpd').with_ensure('absent')
    }
  end
end
