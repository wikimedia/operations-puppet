require 'spec_helper'

describe 'osm::planet_import', :type => :define do
    let(:title) { 'somedb' }
    let(:facts) do {
        :memoryfree => '1000 MB',
        }
    end
    let(:params) do {
        :input_pbf_file => '/nonexistent',
        }
    end
    context 'with ensure present' do
        it { should contain_exec('load_900913-somedb') }
        it { should contain_exec('load_planet_osm-somedb') }
    end
end
