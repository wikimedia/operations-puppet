# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'admin' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'test groups no ssh' do
        let(:params) { {groups_no_ssh: ['groups_no_ssh'], always_groups: ['ops', 'absent']}}
        let(:data) do
          {
            'groups' => {
              'absent' => { 'members' => ['absent_user'] },
              'groups_no_ssh' => { 'members' => ['no_ssh_user'] },
              'ops' => { 'members' => ['ops_user'] },
            },
            'users' => {
              'absent_user' => {
                'ensure' => 'absent',
                'git' => 500,
                'name' => 'absent user',
                'uid' => 1001,
                'ssh_keys' => [],
              },
              'no_ssh_user' => {
                'ensure' => 'present',
                'git' => 500,
                'name' => 'no ssh user',
                'uid' => 1002,
                'ssh_keys' => [],
              },
              'ops_user' => {
                'ensure' => 'present',
                'git' => 500,
                'name' => 'no ssh user',
                'uid' => 1002,
                'ssh_keys' => ['SSH KEY'],
              },
              'no_group_user' => {
                'ensure' => 'present',
                'git' => 500,
                'name' => 'no ssh user',
                'uid' => 1003,
                'ssh_keys' => ['SSH KEY'],
              },
              'system_user' => {
                'ensure' => 'present',
                'git' => 500,
                'name' => 'no ssh user',
                'uid' => 901,
                'system' => true,
                'home_dir' => '/dev/null',
                'ssh_keys' => [],
              }
            }
          }
        end
        let(:pre_condition) do
          "function loadyaml($path) {
            #{data}
          }"
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_admin__hashuser('ops_user').with_ensure_ssh_key(true) }
        it { is_expected.to contain_user('ops_user').with(ensure: 'present', home: '/home/ops_user') }
        it { is_expected.to contain_admin__hashuser('no_ssh_user').with_ensure_ssh_key(false) }
        it { is_expected.to contain_user('no_ssh_user').with_ensure('present') }
        it { is_expected.to contain_admin__hashuser('system_user').with_ensure_ssh_key(false) }
        it { is_expected.to contain_user('system_user').with_ensure('present') }
        it { is_expected.to contain_user('absent_user').with_ensure('absent') }
        describe 'test all groups' do
          let(:params)  { super().merge(groups: ['all-users']) }
          it { is_expected.to contain_user('no_group_user').with_ensure('present') }
          it do
            is_expected.to contain_exec('all-users_ensure_members')
              .with_command(/\bops_user\b/)
              .with_command(/\bno_ssh_user\b/)
              .with_command(/\bno_group_user\b/)
              .without_command(/\babsent_user\b/)
              .without_command(/\bsystem_user\b/)
          end
        end
      end
    end
  end
end
