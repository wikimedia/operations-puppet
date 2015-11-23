require 'spec_helper'

describe 'osm::planet_sync', :type => :define do
    let(:title) { 'somedb' }
    let(:facts) do {
        :memoryfree => '1000 MB',
        }
    end
    let(:params) do {
        :osmosis_dir => '/srv/osmosis',
        :period => 'minute',
        }
    end
    context 'with ensure present' do
        it { should contain_cron('planet_sync-somedb') }
        it { should contain_file('/srv/osmosis/configuration.txt').with_content(/minute/) }
    end
end
