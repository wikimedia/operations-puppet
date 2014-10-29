require 'spec_helper'

describe 'backup::set', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :jobdefaults => 'unimportant',
    }
    }
    let(:pre_condition) do
        [
            'File <| |>',
            'define bacula::client::job($fileset, $jobdefaults) {}',
        ]
    end
    it 'should create valid content for /etc/update-motd.d/06-backups-something' do
        should contain_file("/etc/update-motd.d/06-backups-#{title}").with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0555',
        }) \
        .with_content(/Backed up on this host: something/)
    end
end
