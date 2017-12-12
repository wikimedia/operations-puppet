require 'spec_helper'

describe 'osm::planet_sync', :type => :define do
    let(:title) { 'somedb' }

    context 'with ensure present' do
        let(:params) { {
            :osmosis_dir => '/srv/osmosis',
            :period      => 'minute',
            :pg_password => 'secret',
        } }

        context 'on Ubuntu Precise' do
            let(:facts) { {
                :lsbdistrelease => 'Precise',
                :lsbdistid      => 'Ubuntu',
                :memorysize_mb  => 64 * 1024,
            }}

            it { should contain_cron('planet_sync-somedb') }
            it { should contain_file('/srv/osmosis/configuration.txt').with_content(/minute/) }
            it { should contain_file('/usr/local/bin/replicate-osm').with_content(/--input-reader libxml2/) }
        end

        context 'on Debian Jessie' do
            let(:facts) { {
                :lsbdistrelease => 'Jessie',
                :lsbdistid      => 'Debian',
                :memorysize_mb  => 64 * 1024,
            }}
            it { should contain_file('/usr/local/bin/replicate-osm').with_content(/--input-reader xml/) }
        end
    end
end
