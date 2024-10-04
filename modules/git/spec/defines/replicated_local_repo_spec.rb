# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'git::replicated_local_repo' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'foobar' }
      let(:facts) { os_facts }
      let(:params) {{
        servers: [],
        user: 'pinkunicorn',
        user_homedir: '/home/pinkunicorn',
        ssh_pubkey: 'foobar_pub',
        ssh_privkey: sensitive('foobar_priv'),
      }}
      context 'without_servers' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('git init foobar')
          .with_command(%r{git -C '/srv/git/foobar' init})
          .with_creates('/srv/git/foobar/.git')
        }
        it { is_expected.to contain_file('/srv/git/foobar/.git/hooks/post-commit').with_ensure('absent') }
      end
      context 'with_servers' do
        let(:facts) {
          super().merge(
            {:networking => {:fqdn => 'test1.foo'}}
          )
        }
        let(:params) { super().merge({servers: ['test1.foo', 'test2.foo']}) }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/srv/git/foobar/.git/hooks/post-commit')
          .with_ensure('file')
          .without_content(/test1.foo\"/)
          .with_content(/test2.foo\"/)
        }
        it { is_expected.to contain_file('/home/pinkunicorn/.ssh/id_foobar')
          .with_content(sensitive(/foobar_priv/))
          .with_mode('0600')
          .with_owner('pinkunicorn')
        }
        it { is_expected.to contain_ssh__userkey('pinkunicorn')
          .with_content('foobar_pub')
        }
        it { is_expected.to contain_file('/home/pinkunicorn/.ssh/ssh_wrapper_foobar')
          .with_content(%r{-i '/home/pinkunicorn/.ssh/id_foobar'})
        }
      end
    end
  end
end
