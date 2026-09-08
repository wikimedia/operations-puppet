require 'spec_helper'
describe 'rspamd' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default values for all parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('rspamd') }
      end

      context 'when declaring manage_package_repo is false' do
        let :params do
          {
            manage_package_repo: false
          }
        end

        it { is_expected.to contain_class('rspamd::repo') }
        it { is_expected.not_to contain_class('rspamd::repo::apt_stable') }
        it { is_expected.not_to contain_class('rspamd::repo::rpm_stable') }
      end
    end
  end
end
