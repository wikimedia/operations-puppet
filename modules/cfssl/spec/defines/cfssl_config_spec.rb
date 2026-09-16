# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'cfssl::config' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'test_config' }
      describe 'default run failes' do
        it do
          is_expected.to compile
            .and_raise_error(/auth_keys must have an entry for 'default_auth'/)
        end
      end
      context 'with default auth_keys entry' do
        let(:params) do
          {
            auth_keys: {
              'default_auth' => {
                'key' => 'aaaabbbbccccdddd',
                'type' => 'standard',
              }
            }
          }
        end

        describe 'default run should pass' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/"default_auth":\s*{\s*"key":\s*"aaaabbbbccccdddd"/x))
              .with_content(sensitive(/"signing":\s*{\s*"default":\s*{\s*"auth_key":\s*"default_auth"/x))
          end
        end
      end
      context 'change default auth_keys entry' do
        let(:params) do
          {
            default_expiry: '42h',
            default_usages: ['signing'],
            auth_keys: {
              'default_auth' => {
                'key' => 'aaaabbbbccccdddd',
                'type' => 'standard',
              },
              'foobar' => {
                'key' => 'ddddccccbbbbaaaa',
                'type' => 'standard',
              }
            },
            profiles: {
              'override_auth' => {
                'auth_key' => 'foobar',
              },
              'override_expiry' => {
                'expiry' => '24h',
              },
              'override_usages' => {
                'usages' => ['any'],
              }
            }
          }
        end

        describe 'default run should pass' do
          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "default_auth":\s*{
                                         \s*"key":\s*"aaaabbbbccccdddd",
                                         \s*"type":\s*"standard"\s*
                                      }/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "default":\s*{
                                         \s*"auth_key":\s*"default_auth",
                                         \s*"usages":\s*\[\s*"signing"\s*\],
                                         \s*"expiry":\s*"42h"\s*
                                     \s*}/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_auth":\s*{
                                         \s*"auth_key":\s*"foobar",
                                         \s*"expiry":\s*"42h",
                                         \s*"usages":\s*\[\s*"signing"\s*\]
                                       \s*}/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_expiry":\s*{
                                        \s*"auth_key":\s*"default_auth",
                                        \s*"expiry":\s*"24h",
                                        \s*"usages":\s*\[\s*"signing"\s*\]
                                      /x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_usages" :\s* {
                                        \s*"auth_key":\s*"default_auth",
                                        \s*"expiry":\s*"42h",
                                        \s*"usages":\s*\[\s*"any"\s*\]
                                      /x))
          end
        end
        describe 'Add default_crl_url' do
          let(:params) { super().merge(default_crl_url: 'https://crl.example.org') }

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default":\s*{
                                      \s*"auth_key":\s*"default_auth",
                                      \s*"usages":\s*\[\s*"signing"\s*\],
                                      \s*"expiry":\s*"42h",
                                      \s*"crl_url":\s*"https://crl.example.org"
                                     \s*}}x))
          end
        end
        describe 'Add default_ocsp_url' do
          let(:params) { super().merge(default_ocsp_url: 'https://ocsp.example.org') }

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default":\s*{
                                       \s*"auth_key":\s*"default_auth",
                                       \s*"usages":\s*\[\s*"signing"\s*\],
                                       \s*"expiry":\s*"42h",
                                       \s*"ocsp_url":\s*"https://ocsp.example.org"
                                     \s*}}x))
          end
        end
        describe 'Add default_ocsp_url and default_crl_url' do
          let(:params) do
            super().merge(default_crl_url: 'https://crl.example.org', default_ocsp_url: 'https://ocsp.example.org')
          end

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default":\s*{
                                       \s*"auth_key":\s*"default_auth",
                                       \s*"usages":\s*\[\s*"signing"\s*\],
                                       \s*"expiry":\s*"42h",
                                       \s*"crl_url":\s*"https://crl.example.org",
                                       \s*"ocsp_url":\s*"https://ocsp.example.org"
                                     \s*}}x))
          end
        end
      end
    end
  end
end
