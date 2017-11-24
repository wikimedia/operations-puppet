require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8'], # we cannot support stretch atm because of a bug in the service provider in
      # the puppet gem
    }
  ]
}

describe 'authdns' do
  let(:node) { 'testhost.eqiad.wmnet' }

  on_supported_os(test_on).each do |os, facts|
    facts[:initsystem] = 'systemd'
    let(:facts) { facts }
    let(:params) { {
        :lvs_services => {},
        :discovery_services => {},
    } }
    let(:pre_condition) { [
        'define git::clone($directory, $origin, $branch,$owner,$group) {}',
        'define monitoring::service($description,$check_command) {}',
        'define ssh::userkey($content) {}',
        'define sudo::user($privileges) {}',
        'class confd($prefix) {}',
        'package{ "git": }',
    ] }
    it { is_expected.to compile.with_all_deps  }
  end
end

describe 'authdns::lint' do
  on_supported_os(test_on).each do |os, facts|
    it { should compile }
  end
end
