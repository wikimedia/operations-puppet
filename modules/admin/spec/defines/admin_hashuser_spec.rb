# SPDX-License-Identifier: Apache-2.0

require_relative '../../../../rake_modules/spec_helper'

describe 'admin::hashuser' do
  on_supported_os(WMFConfig.test_on(10, 12)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
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
              'ssh_keys' => ['SSH KEY'],
            },
            'ops_user' => {
              'ensure' => 'present',
              'git' => 500,
              'name' => 'ops user',
              'uid' => 1003,
              'ssh_keys' => ['SSH KEY'],
            },
          }
        }
      end
      let(:pre_condition) do
        "
        class admin () {
          $data = #{data}
        }

        class { 'admin': }"
      end

      let(:params) {{ ensure_ssh_key: true }}

      describe 'absent user' do
        let(:title) { 'absent_user' }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_admin__user('absent_user').with_ensure('absent')
        end
      end

      describe 'no ssh user' do
        let(:title) { 'no_ssh_user' }
        let(:params) {{ ensure_ssh_key: false }}

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_admin__user('no_ssh_user')
            .with_ensure('present')
            .with_ssh_keys([])
        end
      end

      describe 'ops user' do
        let(:title) { 'ops_user' }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_admin__user('ops_user')
            .with_ensure('present')
            .with_ssh_keys(['SSH KEY'])
        end
      end
    end
  end
end
