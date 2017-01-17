require 'spec_helper'

describe 'mirrors::debian', :type => :class do

    it do
        should contain_file('/srv/mirrors/debian').with({
            'ensure' => 'directory',
            'owner'  => 'mirror',
            'group'  => 'mirror',
            'mode'   => '0755',
        })
    end
    it do
        should contain_file('/var/lib/mirror/archvsync/').with({
            'ensure'  => 'directory',
            'owner'   => 'mirror',
            'group'   => 'mirror',
            'mode'    => '0755',
            'source'  => 'puppet:///modules/mirrors/archvsync',
        })
    end
    it do
        should contain_file('/var/lib/mirror/archvsync/etc/ftpsync.conf').with({
            'ensure'  => 'present',
            'owner'   => 'mirror',
            'group'   => 'mirror',
            'mode'    => '0555',
        })
    end
    it do
        # 18eaf6c70 changed to push mirroring
        should_not contain_cron('update-debian-mirror')
    end
end
