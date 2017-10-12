require 'spec_helper'

describe 'git::clone' do
    let(:title) { 'operations/puppet' }
    context 'when enabling $bare' do
        let(:params) { {
            :directory => 'operations/puppet.git',
            :bare => true,
        } }
        it 'git clone is passed --bare' do
            should contain_exec('git_clone_operations/puppet')
                .with_command(/ --bare /)
        end
    end
end
