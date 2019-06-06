require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['9'],
    }
  ]
}

describe 'profile::mediawiki::php' do
  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts){ facts }
      let(:node_params) { {
                            :site => 'eqiad',
                            :realm => 'production',
                            :test_name => 'mediawiki_php',
                            :initsystem => 'systemd',
                            :cluster => 'appserver',
                            :numa_networking => 'off',
                          } }
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
