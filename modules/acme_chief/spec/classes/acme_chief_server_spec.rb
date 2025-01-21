# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'acme_chief::server' do
  let(:pre_condition) { 'include apt' } # provides Exec[apt-get update]
  let(:params) do
    { 'active_host' => 'acmechief1001.eqiad.wmnet' }
  end
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      context "defaults" do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('acme-chief') }
      end
      context "with several accounts" do
        let(:params) { super().merge(
          {
            'accounts' => {
              '6e01c693ed6e9d9a6b5930923ecef104' => {
                'regr' => '',
                'directory' => 'https://acme-staging-v02.api.letsencrypt.org/directory',
                'default' => true,
              },
              '7ee51c01616dea9c3cad10790392bebc' => {
                'regr' => '',
                'directory' => 'https://acme-staging-v02.api.letsencrypt.org/directory',
              },
            },
          })
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/acme-chief/config.yaml').with_owner('acme-chief').with_content(<<-EOM
---
accounts:
- id: 6e01c693ed6e9d9a6b5930923ecef104
  directory: https://acme-staging-v02.api.letsencrypt.org/directory
  default: true
- id: 7ee51c01616dea9c3cad10790392bebc
  directory: https://acme-staging-v02.api.letsencrypt.org/directory
certificates: {}
challenges: {}
EOM
        ) }
      end
    end
  end
end
