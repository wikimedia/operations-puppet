# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'ceph::auth::verify' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'Installs the verification script' do
        it { is_expected.to contain_file('/usr/local/sbin/verify-cephx-keys')
          .with_mode('0555')
          .with_owner('root')
          .with_source('puppet:///modules/ceph/verify_cephx_keys.py')
        }
      end
    end
  end
end
