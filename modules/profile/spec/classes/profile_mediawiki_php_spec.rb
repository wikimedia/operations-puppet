require_relative '../../../../rake_modules/spec_helper'

describe 'profile::mediawiki::php' do
  on_supported_os(WMFConfig.test_on(9)).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:params) {
        {
          :enable_fpm => true,
          :apc_shm_size => '128M'
        }
      }
      let(:pre_condition) do
        'class profile::base ( $notifications_enabled = 1 ){}
        include profile::base'
      end

      context "with default params" do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
