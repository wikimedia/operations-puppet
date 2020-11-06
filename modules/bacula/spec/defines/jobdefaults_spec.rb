require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::director::jobdefaults', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'something' }
      let(:params) { {
        :when => 'never',
        :pool => 'testpool',
      }
      }
      let(:pre_condition) do
        "class {'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
      }
      class profile::base ( $notifications_enabled = 1 ){}
      include profile::base
      class {'base::puppet': ca_source => 'puppet:///files/puppet/ca.production.pem'}"
      end

      it 'should create /etc/bacula/conf.d/jobdefaults-something.conf' do
        should contain_file('/etc/bacula/conf.d/jobdefaults-something.conf').with({
          'ensure'  => 'present',
          'owner'   => 'root',
          'group'   => 'bacula',
          'mode'    => '0440',
        }) \
          .with_content(/Name = something/) \
          .with_content(/Type = Backup/) \
          .with_content(/Accurate = no/) \
          .with_content(/Spool Data = no/) \
          .with_content(/Schedule = never/) \
          .with_content(/Pool = testpool/) \
          .with_content(/Priority = 10/)
      end
    end
  end
end
