# SPDX-License-Identifier: Apache-2.0
# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'ssh::publish_fingerprints' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:params) { { document_root: '/tmp' } }
      let(:pre_condition) do
        "function puppetdb::query_facts($_facts) {
           {
            'foo' => {
              'networking' => {
                'ip' => '192.0.2.1',
                'ip6' => '2001:db8::1',
              },
              'ssh' => {
                'ecdsa' => {
                  'type' => 'ssh-ecdsa',
                  'key'  => 'ecdsa-key',
                  'fingerprints' => {
                    'sha1' => 'SSHFP 1 1 ecdsa-fingerprint',
                    'sha256' => 'SSHFP 1 2 ecdsa-fingerprint',
                  },
                },
                'ed25519' => {
                  'type' => 'ssh-ed25519',
                  'key'  => 'ed25519-key',
                  'fingerprints' => {
                    'sha1' => 'SSHFP 1 1 ed25519-fingerprint',
                    'sha256' => 'SSHFP 1 2 ed25519-fingerprint',
                  },
                },
                'rsa' => {
                  'type' => 'ssh-rsa',
                  'key'  => 'rsa-key',
                  'fingerprints' => {
                    'sha1' => 'SSHFP 1 1 rsa-fingerprint',
                    'sha256' => 'SSHFP 1 2 rsa-fingerprint',
                  },
                },
              },
            }
          }
        }"
      end

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/tmp/ssh-fingerprints.txt')
            .with_content(
              /foo:
              \s+ecdsa:
              \s+sha1:\secdsa-fingerprint
              \s+sha256:\secdsa-fingerprint
              \s+ed25519:
              \s+sha1:\sed25519-fingerprint
              \s+sha256:\sed25519-fingerprint
              \s+rsa:
              \s+sha1:\srsa-fingerprint
              \s+sha256:\srsa-fingerprint
              /x
          )
        end
        ['ecdsa', 'ed25519', 'rsa'].each do |key|
          it do
            is_expected.to contain_file("/tmp/known_hosts.#{key}")
              .with_content(/foo,192.0.2.1,2001:db8::1\sssh-#{key}\s#{key}-key/)
          end
        end
      end
    end
  end
end
