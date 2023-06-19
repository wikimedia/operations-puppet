require_relative '../../../../rake_modules/spec_helper'

describe 'git::clone' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'testing_repo' }
      let(:facts) { os_facts }
      let(:params) {{ directory: '/srv/git/testing_repo' }}

      context 'dummy invocation' do
        it 'checkouts a workspace' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_command('/usr/bin/git  clone https://gerrit.wikimedia.org/r/testing_repo /srv/git/testing_repo')
        end
        it 'tracks the proper created file' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_creates('/srv/git/testing_repo/.git/config')
        end
      end

      context 'when enabling $bare' do
        let(:params) { super().merge(bare: true) }
        it 'git clone is passed --bare' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_command(/ --bare /)
        end
      end
    end
  end
end
