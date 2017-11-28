require 'spec_helper'

describe 'postgresql::server', :type => :class do
    let(:facts) { { :lsbdistcodename => 'jessie' } }

    context 'ensure present' do
        let(:params) { {
            :ensure => 'present',
        } }

        it { should contain_package('postgresql-9.4').with_ensure('present') }
        it { should contain_package('postgresql-9.4-debversion').with_ensure('present') }
        it { should contain_package('postgresql-client-9.4').with_ensure('present') }
        it { should contain_package('libdbi-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_file('/etc/postgresql/9.4/main/postgresql.conf').with_ensure('present') }
        it { should contain_file('/var/lib/postgresql').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.4').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.4/main').with_ensure('directory') }
        it { should contain_service('postgresql@9.4-main').with_ensure('running') }

        context 'with custom root_dir' do
            let(:params) { {
                :ensure => 'present',
                :root_dir => '/srv/postgresql'
            } }

            it { should contain_file('/srv/postgresql').with_ensure('directory') }
            it { should contain_file('/srv/postgresql/9.4').with_ensure('directory') }
            it { should contain_file('/srv/postgresql/9.4/main').with_ensure('directory') }
        end
    end

    context 'ensure absent' do
        let(:params) { {
            :ensure => 'absent',
        } }

        it { should contain_file('/etc/postgresql/9.4/main/postgresql.conf').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/9.4').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/9.4/main').with_ensure('absent') }
        it { should contain_service('postgresql@9.4-main').with_ensure('stopped') }
    end

    context 'with includes' do
        let(:params) { {
            :ensure => 'present',
            :includes => ['a.conf', 'b.conf'],
        } }

        it { should contain_file('/etc/postgresql/9.4/main/postgresql.conf')
                        .with_content(/include 'a.conf'/)
                        .with_content(/include 'b.conf'/)
        }
    end

    context 'ensure jessie' do
        let(:params) { {
            :ensure => 'present',
        } }

        it { should contain_package('postgresql-9.4').with_ensure('present') }
        it { should contain_package('postgresql-9.4-debversion').with_ensure('present') }
        it { should contain_package('postgresql-client-9.4').with_ensure('present') }
        it { should contain_package('libdbi-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_package('libdbd-pg-perl').with_ensure('present') }
        it { should contain_file('/etc/postgresql/9.4/main/postgresql.conf').with_ensure('present') }
        it { should contain_file('/var/lib/postgresql').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.4').with_ensure('directory') }
        it { should contain_file('/var/lib/postgresql/9.4/main').with_ensure('directory') }
        it { should contain_service('postgresql@9.4-main').with_ensure('running') }
    end
end
