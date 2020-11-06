require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::director::schedule', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'something' }
      let(:params) { {
        :runs => [
          { 'level' => 'Full', 'at' => '1st Sat at 00:00'},
          { 'level' => 'Differential', 'at' => '3rd Sat at 00:00'},
        ]
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

      it 'should create /etc/bacula/conf.d/schedule-something.conf' do
        should contain_file('/etc/bacula/conf.d/schedule-something.conf').with({
          'ensure'  => 'present',
          'owner'   => 'root',
          'group'   => 'bacula',
          'mode'    => '0440',
        }) \
          .with_content(/Name = something/) \
          .with_content(/Run = Level=Full 1st Sat at 00:00/) \
          .with_content(/Run = Level=Differential 3rd Sat at 00:00/)
      end
    end
  end
end
