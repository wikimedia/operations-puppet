require_relative '../../../../rake_modules/spec_helper'
describe 'profile::spicerack::reposync' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # By default we use puppetdb so need to provide something here
      let(:params) { {remotes: ['remote.example.org']} }

      describe 'defaults' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
