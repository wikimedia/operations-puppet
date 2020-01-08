require 'spec_helper'

describe 'postgresql::spatialdb', :type => :define do
    let(:title) { 'somedb' }
    let(:params) { { :ensure => 'present' } }
    let(:facts) do
      {
        'lsbdistcodename' => 'jessie',
        'lsbdistrelease' => '8.6',
        'lsbdistid' => 'Debian'
      }
    end

    context 'with ensure present' do
        it { should contain_exec('create_postgres_db_somedb') }
        it { should contain_exec('create_extension_postgis_on_somedb') }
        it { should contain_exec('create_extension_hstore_on_somedb') }
    end
end

describe 'postgresql::spatialdb', :type => :define do
    let(:title) { 'somedb' }
    let(:params) { { :ensure => 'absent' } }
    let(:facts) do
      {
        'lsbdistcodename' => 'jessie',
        'lsbdistrelease' => '8.6',
        'lsbdistid' => 'Debian'
      }
    end

    context 'with ensure absent' do
        it { should contain_exec('drop_postgres_db_somedb') }
    end
end
