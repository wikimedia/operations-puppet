# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'community_civicrm' do
  let(:pre_condition){ 'service { "apache2": ensure => running }'}
  on_supported_os(WMFConfig.test_on(11)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          config_nonce: 'random',
          git_branch: 'main',
          hash_salt: 'salt',
          site_name: 'community.example.org',
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/var/www/community_civicrm/web/sites/default/civicrm.settings.php')
            .with_content(%r{'CIVICRM_UF_BASEURL'\s+,\s+'https://community.example.org'})
        end
      end
    end
  end
end
