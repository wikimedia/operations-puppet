require_relative '../../../../rake_modules/spec_helper'
require 'rspec-puppet/cache'

describe 'mariadb::packages' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "On #{os}" do
      let(:facts) { os_facts }
      it { is_expected.to compile }
    end
  end
end
