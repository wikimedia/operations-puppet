# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'puppetserver' do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      context "with extra_mounts" do
        let(:params) do
          {
            extra_mounts: {
              'test_mount1' => '/srv/extra_mount1',
              'test_mount2' => '/srv/extra_mount2'
            }
          }
        end
        it do
          is_expected.to contain_file('/etc/puppet/fileserver.conf')
            .with_content(%r{
                          \[test_mount1\]
                          \s+path\s/srv/extra_mount1\s+
                          \[test_mount2\]
                          \s+path\s/srv/extra_mount2
                          }x)
        end
      end
    end
  end
end
