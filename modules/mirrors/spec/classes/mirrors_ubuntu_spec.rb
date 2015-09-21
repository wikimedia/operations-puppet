require 'spec_helper'

describe 'mirrors::ubuntu', :type => :class do

    it do
        should contain_file('/srv/mirrors/ubuntu/').with({
            'ensure' => 'directory',
            'owner'  => 'mirror',
            'group'  => 'mirror',
            'mode'   => '0755',
        },)
    end
    it do
        should contain_file('/usr/local/sbin/update-ubuntu-mirror').with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'root',
            'mode'    => '0555',
            'source'  => 'puppet:///modules/mirrors/update-ubuntu-mirror',
        },)
    end
    it do
        should contain_cron('update-ubuntu-mirror').with({
            'ensure'  => 'present',
            'command' => '/usr/local/sbin/update-ubuntu-mirror 1>/dev/null 2>/var/lib/mirror/mirror.err.log',
            'user'    => 'mirror',
            'hour'    => '*/6',
            'minute'  => '43',
        },)
    end
end
