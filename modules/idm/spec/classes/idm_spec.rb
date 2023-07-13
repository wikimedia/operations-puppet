# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'idm::jobs' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          base_dir: '/foo',
          etc_dir: '/foo',
          present: 'present',
          project: 'foo',
          venv: 'bar',
          user: 'foobar'
        }
      end
      describe 'test compilation with default parameters' do
        it { is_expected.to compile.with_all_deps }
      end
      it do
        is_expected.to contain_systemd__timer__job('sync_bitu_username_block')
          .with_ensure('present')
          .with_command('/foo/venv/bin/python /foo/foo/manage.py blocklist_wmf')
      end
      describe "changeing base_dir" do
        let(:params) { super().merge(base_dir: '/foobar') }
        it do
          is_expected.to contain_systemd__timer__job('sync_bitu_username_block')
            .with_ensure('present')
            .with_command('/foobar/venv/bin/python /foobar/foo/manage.py blocklist_wmf')
        end
      end
    end
  end
end
