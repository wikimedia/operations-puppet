# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'
describe 'profile::gerrit::proxy' do
  on_supported_os(WMFConfig.test_on(11, 12)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) {
        {
          # Overrides for hosts specific Hiera values
          'ipv4' => '198.51.100.1',
          'ipv6' => '2001:DB8::CAFE',
          'keepalive_timeout' => 120,
          'max_keepalive_requests' => 100,
          'keepalive_toggle' => true,
        }
      }
      let(:pre_condition) do
        <<-PUPPET
        class network::constants {
          $production_networks = ['192.0.2.0/24', '2001:db8::/32']
          $cloud_networks      = ['198.51.100.0/24', '2001:db8:feed::/48']
        }
        PUPPET
      end

      it { is_expected.to compile.with_all_deps }
      it "Symlink images from $GERRIT_SITE into document root" do
        gerrit_site = '/var/lib/gerrit/review_site'
        is_expected.to contain_file('/var/www/page-bkg.cache.jpg')
          .with_target("#{gerrit_site}/static/page-bkg.cache.jpg")
      end
    end
  end
end
