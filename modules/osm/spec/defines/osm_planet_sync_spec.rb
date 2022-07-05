# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'osm::planet_sync', :type => :define do
    let(:title) { 'somedb' }

    context 'with ensure present' do
        let(:params) { {
            :use_proxy   => false,
            :engine      => "osm2pgsql",
            :proxy_host  => 'proxy.example.org',
            :proxy_port  => 8080,
            :osmosis_dir => '/srv/osmosis',
            :period      => 'minute',
        } }

        context 'on Debian Stretch' do
            let(:facts) { {
                :lsbdistrelease => 'Stretch',
                :lsbdistid      => 'Debian',
                :memorysize_mb  => 64 * 1024,
                :processorcount => 4,
            }}
            it { should contain_file('/usr/local/bin/replicate-osm').with_content(/--input-reader xml/) }
        end
    end
end
