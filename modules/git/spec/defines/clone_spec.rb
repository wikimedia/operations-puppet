require 'spec_helper'

describe 'git::clone' do
    let(:title) { 'operations/puppet' }

    context 'dummy invocation' do
        let(:params) { {
            :directory => '/srv/git/operations/puppet'
        } }
        it 'checkouts a workspace' do
            should contain_exec('git_clone_operations/puppet')
                .without_command(/ --bare /)
        end
        it 'tracks the proper created file' do
            should contain_exec('git_clone_operations/puppet')
                .with_creates('/srv/git/operations/puppet/.git/config')
        end
    end

    context 'when enabling $bare' do
        let(:params) { {
            :directory => '/srv/git/operations/puppet.git',
            :bare => true,
        } }
        it 'git clone is passed --bare' do
            should contain_exec('git_clone_operations/puppet')
                .with_command(/ --bare /)
        end
        it 'tracks the proper created file' do
            should contain_exec('git_clone_operations/puppet')
                .with_creates('/srv/git/operations/puppet.git/config')
        end
    end
end
