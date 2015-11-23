require 'spec_helper'

describe 'osm::usergrants', :type => :define do
    let(:title) { 'somedb' }
    let(:params) do {
        :postgresql_user => 'someuser',
        :ensure => 'present',
        }
    end
    context 'with ensure present' do
        it { should contain_exec('grant_osm_rights-somedb') }
    end
end

describe 'osm::usergrants', :type => :define do
    let(:title) { 'somedb' }
    let(:params) do {
        :postgresql_user => 'someuser',
        :ensure => 'absent',
        }
    end
    context 'with ensure absent' do
        it { should contain_exec('revoke_osm_rights-somedb') }
    end
end
