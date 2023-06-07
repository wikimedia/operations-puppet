require_relative '../../../../rake_modules/spec_helper'

describe 'git::clone' do
  on_supported_os(WMFConfig.test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'testing_repo' }
      let(:facts) { os_facts }
      let(:params) {{ directory: '/srv/git/testing_repo' }}

      context 'dummy invocation' do
        it { is_expected.to compile.with_all_deps }
        it 'checkouts a workspace' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_command('/usr/bin/git clone https://gerrit.wikimedia.org/r/testing_repo /srv/git/testing_repo')
        end
        it 'tracks the proper created file' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_creates('/srv/git/testing_repo/.git/config')
        end
        it 'does exec with umask 022' do
          should contain_exec('git_clone_testing_repo')
            .with_umask('022')
        end
      end

      context 'when enabling $bare' do
        let(:params) { super().merge(bare: true) }
        it 'git clone is passed --bare' do
          is_expected.to contain_exec('git_clone_testing_repo')
            .with_command(/ --bare /)
        end
      end
      context 'when enabling $bare' do
        let(:params) { super().merge(ensure: 'latest') }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('git_pull_testing_repo')
            .with_command(/ pull /)
        end
      end
      context 'when enabling $bare' do
        let(:params) { super().merge(ensure: 'latest', update_method: 'checkout') }
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('git_checkout_testing_repo')
            .with_command(/ checkout --force /)
        end
      end

      context 'when shared is enabled' do
        let(:params) { {
          :directory => '/srv/deployment/application',
          :shared    => true,
        } }
        it 'does exec with umask 002' do
          should contain_exec('git_clone_testing_repo').with_umask('002')
        end
      end

      context 'when mode prevents others (0440)' do
        let(:params) { {
          :directory => '/srv/deployment/application',
          :mode      => '0440',
        } }
        it 'does exec with umask 337' do
          should contain_exec('git_clone_testing_repo').with_umask('337')
        end
      end
      context 'when mode only allows self (0700)' do
        let(:params) { {
          :directory => '/srv/deployment/application',
          :mode      => '0700',
        } }
        it 'does exec with umask 077' do
          should contain_exec('git_clone_testing_repo').with_umask('077')
        end
      end
    end
  end
end
