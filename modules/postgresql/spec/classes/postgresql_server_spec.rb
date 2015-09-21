require 'spec_helper'

describe 'postgresql::server', :type => :class do
    let(:params) { {
        :pgversion => '9.1',
        :ensure => 'present',
        }
    }

    context 'ensure present' do
        it { should contain_package('postgresql-9.1').with_ensure('present') }
        it { should contain_package('postgresql-9.1-debversion').with_ensure('present') }
        it { should contain_package('postgresql-client-9.1').with_ensure('present') }
        it { should contain_package('libdbi-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf').with_ensure('present') }
        it do
            should contain_service('postgresql').with({
            'ensure'  => 'running'
            })
        end
    end
end

describe 'postgresql::server', :type => :class do
    let(:params) { {
        :pgversion => '9.1',
        :ensure => 'absent',
        }
    }

    context 'ensure absent' do
        it { should contain_package('postgresql-9.1').with_ensure('absent') }
        it { should contain_package('postgresql-9.1-debversion').with_ensure('absent') }
        it { should contain_package('postgresql-client-9.1').with_ensure('absent') }
        it { should contain_package('libdbi-perl').with_ensure('absent') }
        it { should contain_package('libdbd-pg-perl').with_ensure('absent') }
        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf').with_ensure('absent') }
        it do
            should contain_service('postgresql').with({
            'ensure'  => 'stopped'
            })
        end
    end
end

describe 'postgresql::server', :type => :class do
    let(:params) { {
        :pgversion => '9.1',
        :ensure => 'absent',
        :includes => ['a.conf', 'b.conf'],
        }
    }

    context 'with includes' do
        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf').with_content(/include 'a.conf'/) }
    end
end
