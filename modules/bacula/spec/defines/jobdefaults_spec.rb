require 'spec_helper'

describe 'bacula::director::jobdefaults' do
    let(:title) { 'something' }
    let(:params) { {
        :when => 'never',
        :pool => 'testpool',
        }
    }

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
