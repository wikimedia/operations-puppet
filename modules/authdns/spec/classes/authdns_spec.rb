require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
      # the puppet gem
    }
  ]
}

describe 'authdns' do
  let(:node) { 'testhost.eqiad.wmnet' }

  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:params) { {
                       :lvs_services => {},
                       :discovery_services => {},
                     } }
      let(:pre_condition) { [
                              '$site = "test"',
                              'define git::clone($directory, $origin, $branch,$owner,$group) {}',
                              'define monitoring::service($description,$check_command) {}',
                              'define ssh::userkey($content) {}',
                              'define sudo::user($privileges) {}',
                              'class confd($prefix) {}',
                              'package{ "git": }',
                              'include ::apt'
                            ] }
      it { is_expected.to compile.with_all_deps  }
    end
  end
end
