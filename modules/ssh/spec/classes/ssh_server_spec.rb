# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'ssh::server' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      context 'test match_config' do
        let(:params) do
          {
            match_config: [
              {
                'criteria' => 'Host',
                'patterns' => ['*.example.org'],
                'config'   => { 'MaxAuthTries' => '10' },
              },
              {
                'criteria' => 'Address',
                'patterns' => ['192.0.2'],
                'config'   => { 'MaxAuthTries' => '10', 'MaxSessions' => '64:30:128' },
              },
              {
                'criteria' => 'User',
                'patterns' => ['bob', 'fred'],
                'config'   => { 'MaxAuthTries' => '10', 'MaxSessions' => '64:30:128' },
              }
            ]
          }
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/ssh/sshd_config')
            .with_content(/
              Match\sHost\s\*\.example\.org\n
              \s+MaxAuthTries\s10\n
            /x)
            .with_content(/
              Match\sAddress\s192\.0\.2\n
              \s+MaxAuthTries\s10\n
              \s+MaxSessions\s64:30:128\n
            /x)
            .with_content(/
              Match\sUser\sbob,fred
              \s+MaxAuthTries\s10\n
              \s+MaxSessions\s64:30:128\n
            /x)
        end
      end
    end
  end
end
