require 'spec_helper'

describe 'osm::populatedb', :type => :define do
    let(:title) { 'somedb' }
    let(:params) { {
        :input_pbf_file => '/nonexistent',
        }
    }
    context 'with ensure present' do
        it { should contain_exec('load_900913-somedb') }
        it { should contain_exec('load_planet_osm-somedb') }
    end
end
