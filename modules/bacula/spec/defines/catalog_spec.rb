require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::director::catalog', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'something' }
      let(:params) do
        {
          :dbname      => 'bacula',
          :dbuser      => 'bacula',
          :dbhost      => 'bacula-db.example.org',
          :dbport      => '3306',
          :dbpassword  => 'bacula',
        }
      end
      let(:pre_condition) do
        "class {'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
      }
      class profile::base ( $notifications_enabled = 1 ){}
      include profile::base
      class {'base::puppet': ca_source => 'puppet:///files/puppet/ca.production.pem'}"
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
  end
end
