require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::php' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:pre_condition) { "include apt"}
      let(:params) {
        {
          :enable_fpm => true,
          :apc_shm_size => '128M'
        }
      }

      context "with default params" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
