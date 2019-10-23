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
    end
  end
end
