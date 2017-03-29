require 'spec_helper'

describe 'postgresql::spatialdb', :type => :define do
    let(:title) { 'somedb' }
    let(:params) { {
        :ensure => 'present',
        }
    }
    context 'with ensure present' do
        it { should contain_exec('create_postgres_db-somedb') }
        it { should contain_exec('create_plpgsql_lang-somedb') }
        it { should contain_exec('create_postgis-somedb') }
        it { should contain_exec('create_spatial_ref_sys-somedb') }
        it { should contain_exec('create_comments-somedb') }
        it { should contain_exec('create_extension_hstore-somedb') }
    end
end

describe 'postgresql::spatialdb', :type => :define do
    let(:title) { 'somedb' }
    let(:params) { {
        :ensure => 'absent',
        }
    }
    context 'with ensure absent' do
        it { should contain_exec('drop_postgres_db-somedb') }
        it { should contain_exec('drop_plpgsql_lang-somedb') }
    end
end
