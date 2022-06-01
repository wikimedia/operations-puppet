# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'reposync' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
            'networking' => facts[:networking].merge({'fqdn' => 'git.example.org'})
          })
      end
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/srv/reposync').with_ensure('directory')}
        it { is_expected.to contain_file('/etc/spicerack/reposync').with_ensure('directory')}
        it do
          is_expected.to contain_file('/etc/spicerack/reposync/config.yaml')
            .with_ensure('file')
            .with_content(%r{base_dir: "/srv/reposync"})
            .with_content(/remotes: \[\]/)
            .with_content(/repos: \[\]/)
        end
      end
      describe 'test with repos' do
        let(:params) do
          {
            repos: ['foobar'],
            remotes: [
              'git.example.org',     # should be excluded because its fqdn
              'remote.example.org',
            ]
          }
        end
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/etc/spicerack/reposync/config.yaml')
            .with_ensure('file')
            .with_content(%r{base_dir: "/srv/reposync"})
            .with_content(/repos:\n-\sfoobar/)
            .with_content(/remotes:\n-\s+git\.example\.org\n-\s+remote\.example\.org/)
        end
        it { is_expected.to contain_exec('git_init_foobar') }
        it do
          is_expected.to contain_file('/srv/reposync/foobar/hooks/post-update')
            .with_ensure('file')
            .with_mode('0550')
            .with_content("#!/bin/sh\nexec /usr/bin/git update-server-info\n")
        end
        it do
          is_expected.to contain_file('/srv/reposync/foobar/config')
            .with_ensure('file')
            .with_mode('0440')
            .with_content(
              %r{\[remote\s+"git\.example\.org"\]\s+
                url\s+=\s+ssh://root@git\.example\.org/srv/reposync/foobar/\s+
                fetch\s+=\s+\+refs/heads/\*:refs/remotes/git\.example\.org/\*
              }x)
            .with_content(
              %r{\[remote\s+"remote\.example\.org"\]\s+
                url\s+=\s+ssh://root@remote\.example\.org/srv/reposync/foobar/\s+
                fetch\s+=\s+\+refs/heads/\*:refs/remotes/remote\.example\.org/\*
              }x)
        end
      end
    end
  end
end
