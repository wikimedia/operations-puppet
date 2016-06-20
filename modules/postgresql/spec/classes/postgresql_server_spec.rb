require 'spec_helper'

describe 'postgresql::server', :type => :class do

    context 'ensure present' do
        let(:params) { {
            :pgversion => '9.1',
            :ensure => 'present',
        } }

        it { should contain_package('postgresql-9.1').with_ensure('present') }
        it { should contain_package('postgresql-9.1-debversion').with_ensure('present') }
        it { should contain_package('postgresql-client-9.1').with_ensure('present') }
        it { should contain_package('libdbi-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf').with_ensure('present') }
        it { should contain_file('/var/lib/postgresql/').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.1/').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.1/main/').with_ensure('directory') }
        it { should contain_service('postgresql').with_ensure('running') }

        context 'with custom root_dir' do
            let(:params) { {
                :pgversion => '9.1',
                :ensure => 'present',
                :root_dir => '/srv/postgresql'
            } }

            it { should contain_file('/srv/postgresql/').with_ensure('directory') }
            it { should contain_file('/srv/postgresql/9.1/').with_ensure('directory') }
            it { should contain_file('/srv/postgresql/9.1/main/').with_ensure('directory') }
        end
    end

    context 'ensure absent' do
        let(:params) { {
            :pgversion => '9.1',
            :ensure => 'absent',
        } }

        it { should contain_package('postgresql-9.1').with_ensure('absent') }
        it { should contain_package('postgresql-9.1-debversion').with_ensure('absent') }
        it { should contain_package('postgresql-client-9.1').with_ensure('absent') }
        it { should contain_package('libdbi-perl').with_ensure('absent') }
        it { should contain_package('libdbd-pg-perl').with_ensure('absent') }
        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/9.1/').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/9.1/main/').with_ensure('absent') }
        it { should contain_service('postgresql').with_ensure('stopped') }
    end

    context 'with includes' do
        let(:params) { {
            :pgversion => '9.1',
            :ensure => 'present',
            :includes => ['a.conf', 'b.conf'],
        } }

        it { should contain_file('/etc/postgresql/9.1/main/postgresql.conf')
                        .with_content(/include 'a.conf'/)
                        .with_content(/include 'b.conf'/)
        }
    end
end
