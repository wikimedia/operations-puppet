require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::r10k' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) do
        '''
        include profile::puppet::agent
        include httpd
        include prometheus::node_exporter
        '''
      end

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
