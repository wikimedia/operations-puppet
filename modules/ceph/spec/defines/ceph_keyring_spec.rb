require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::keyring', :type => :define do
  on_supported_os(WMFConfig.test_on(10)).each do |os, os_facts|
    context "on #{os}" do
      let(:pre_condition) { 'package { "ceph-common": }' }
      let(:title) { 'my_keyring' }
      let(:facts) { os_facts }
      let(:params) { {:keyring => '/path/to/dummy.keyring'} }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
        it { should contain_file('/path/to/dummy.keyring') }
      end
    end
  end
end
