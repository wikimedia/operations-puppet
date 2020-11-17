require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::ssl' do
  let(:pre_condition) do
    "include httpd
    exec {'compile puppet.conf': command => '/bin/true'}"
  end
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { is_expected.to compile }
    end
  end
end
