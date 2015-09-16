require 'spec_helper'

describe 'osm::planet_import', :type => :define do
    let(:title) { 'somedb' }
    let(:facts) { {
        :memoryfree => '1000 MB'
        }
    }
    let(:params) { {
        :input_pbf_file => '/nonexistent'
        }
    }
    context 'with ensure present' do
        it { should contain_exec('load_900913-somedb') }
        it { should contain_exec('load_planet_osm-somedb') }
    end
end
