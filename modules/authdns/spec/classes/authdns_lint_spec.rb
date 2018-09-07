require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
      # the puppet gem
    }
  ]
}

describe 'authdns::lint' do
  on_supported_os(test_on).each do |os, facts|
    let(:facts) { facts }
    context "On #{os}" do
      it { should compile }
    end
  end
end
