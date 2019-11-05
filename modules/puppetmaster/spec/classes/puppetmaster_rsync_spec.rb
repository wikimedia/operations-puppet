require_relative '../../../../rake_modules/spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'puppetmaster::rsync' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:params) { {
                       :server => 'puppetmaster_host',
                     } }
      let(:node_params) { {
                            'realm' => 'production',
                    } }
      it { should compile }
    end
  end
end
