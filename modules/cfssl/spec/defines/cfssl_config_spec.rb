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
              .with_content(sensitive(/"default_auth":{"key":"aaaabbbbccccdddd"/))
              .with_content(sensitive(/"signing":{"default":{"auth_key":"default_auth"/))
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
                                        "default_auth": {
                                          "key": "aaaabbbbccccdddd",
                                          "type": "standard"
                                      }/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "default": {
                                          "auth_key": "default_auth",
                                          "usages": \["signing"\],
                                          "expiry": "42h"
                                      }/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_auth": {
                                          "auth_key":"foobar",
                                          "expiry": "42h",
                                          "usages": \["signing"\]
                                        }/x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_expiry" : {
                                          "auth_key": "default_auth",
                                          "expiry": "24h",
                                          "usages": \["signing"\]
                                      /x))
          end
          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(/
                                        "override_usages" : {
                                          "auth_key": "default_auth",
                                          "expiry": "42h",
                                          "usages": \["any"\]
                                      /x))
          end
        end
        describe 'Add default_crl_url' do
          let(:params) { super().merge(default_crl_url: 'https://crl.example.org') }

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default": {
                                        "auth_key": "default_auth",
                                        "usages": \["signing"\],
                                        "expiry": "42h",
                                        "crl_url": "https://crl.example.org"
                                      }}x))
          end
        end
        describe 'Add default_ocsp_url' do
          let(:params) { super().merge(default_ocsp_url: 'https://ocsp.example.org') }

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default": {
                                        "auth_key": "default_auth",
                                        "usages": \["signing"\],
                                        "expiry": "42h",
                                        "ocsp_url": "https://ocsp.example.org"
                                      }}x))
          end
        end
        describe 'Add default_ocsp_url and default_crl_url' do
          let(:params) do
            super().merge(default_crl_url: 'https://crl.example.org', default_ocsp_url: 'https://ocsp.example.org')
          end

          it do
            is_expected.to contain_file('/etc/cfssl/test_config.conf')
              .with_content(sensitive(%r{
                                      "default": {
                                        "auth_key": "default_auth",
                                        "usages": \["signing"\],
                                        "expiry": "42h",
                                        "crl_url": "https://crl.example.org",
                                        "ocsp_url": "https://ocsp.example.org"
                                      }}x))
          end
        end
      end
    end
  end
end
