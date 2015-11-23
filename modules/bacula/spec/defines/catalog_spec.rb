require 'spec_helper'

describe 'bacula::director::catalog', :type => :define do
    let(:title) { 'something' }
    let(:params) do {
        :dbname      => 'bacula',
        :dbuser      => 'bacula',
        :dbhost      => 'bacula-db.example.org',
        :dbport      => '3306',
        :dbpassword  => 'bacula',
        }
    end

    it 'should create valid content for /etc/bacula/conf.d/catalog-something.conf' do
        should contain_file('/etc/bacula/conf.d/catalog-something.conf').with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'bacula',
            'mode'    => '0440',
        }) \
        .with_content(/Name = something/) \
        .with_content(/dbname = bacula/) \
        .with_content(/user = bacula/) \
        .with_content(/password = bacula/) \
        .with_content(/DB Address = bacula-db.example.org/) \
        .with_content(/DB Port = 3306/)
    end
end
