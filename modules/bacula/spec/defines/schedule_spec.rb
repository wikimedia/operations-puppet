require 'spec_helper'

describe 'bacula::director::schedule', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
        :runs => [
            { 'level' => 'Full', 'at' => '1st Sat at 00:00'},
            { 'level' => 'Differential', 'at' => '3rd Sat at 00:00'},
            ]
        }
    }
    let(:facts) do
      {
        'lsbdistrelease' => '10.1',
        'lsbdistid' => 'Debian'
      }
    end
    let(:pre_condition) do
      "class {'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
      }"
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
