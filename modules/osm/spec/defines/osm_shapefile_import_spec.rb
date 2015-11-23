require 'spec_helper'

describe 'osm::shapefile_import', :type => :define do
    let(:title) { 'somedb-shapefile1' }
    let(:params) do {
        :database => 'gis',
        :input_shape_file => '/nonexistent',
        :shape_table      => 'shapes',
        }
    end
    context 'with ensure present' do
        it { should contain_exec('create_shapelines-somedb-shapefile1') }
        it { should contain_exec('load_shapefiles-somedb-shapefile1') }
        it { should contain_exec('delete_shapefiles-somedb-shapefile1') }
    end
end
