require_relative '../../../../rake_modules/spec_helper'

describe 'puppet::agent' do
  let(:pre_condition) {
    [
      'class passwords::puppet::database {}',
      'include apt'
    ]
  }
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts}
      let(:params) { { 'ca_source' => 'puppet:///modules/foo/ca.pem' } }
      it { should compile }
    end
  end
end
