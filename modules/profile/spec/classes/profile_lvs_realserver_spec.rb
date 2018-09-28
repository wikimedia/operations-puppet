require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'profile::lvs::realserver' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:node_params) { { :site => 'testsite', :realm => 'production',
                            :test_name => 'lvs_realserver'} }

      let(:params) {
        {
          'pools' => {'text' => {'service' => 'nginx', 'lvs_group' => 'textlb'}},
          'use_conftool' => false
        }
      }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('lvs::realserver')
                            .with_realserver_ips(["1.1.1.1"])
      }
    end
  end
end
