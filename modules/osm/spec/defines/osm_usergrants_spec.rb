require 'spec_helper'

describe 'osm::usergrants' do
    let(:title) { 'somedb' }
    let(:params) { {
        :postgresql_user => 'someuser',
        :ensure => 'present',
        }
    }
    context 'with ensure present' do
        it { should contain_exec('grant_osm_rights-somedb') }
    end
end

describe 'osm::usergrants' do
    let(:title) { 'somedb' }
    let(:params) { {
        :postgresql_user => 'someuser',
        :ensure => 'absent',
        }
    }
    context 'with ensure absent' do
        it { should contain_exec('revoke_osm_rights-somedb') }
    end
end
