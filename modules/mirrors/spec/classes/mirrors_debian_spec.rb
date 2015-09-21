require 'spec_helper'

describe 'mirrors::debian', :type => :class do

    it do
        should contain_file('/srv/mirrors/debian').with({
            'ensure' => 'directory',
            'owner'  => 'mirror',
            'group'  => 'mirror',
            'mode'   => '0755',
        },)
    end
    it do
        should contain_file('/var/lib/mirror/archvsync/').with({
            'ensure'  => 'directory',
            'owner'   => 'mirror',
            'group'   => 'mirror',
            'mode'    => '0755',
            'source'  => 'puppet:///modules/mirrors/archvsync',
        },)
    end
    it do
        should contain_file('/var/lib/mirror/archvsync/etc/ftpsync.conf').with({
            'ensure'  => 'present',
            'owner'   => 'mirror',
            'group'   => 'mirror',
            'mode'    => '0555',
            'source'  => 'puppet:///modules/mirrors/ftpsync.conf',
        },)
    end
    it do
        should contain_cron('update-debian-mirror').with({
            'ensure'  => 'present',
            'command' => '/var/lib/mirror/archvsync/bin/ftpsync',
            'user'    => 'mirror',
            'hour'    => '*/6',
            'minute'  => '03',
        },)
    end
end
