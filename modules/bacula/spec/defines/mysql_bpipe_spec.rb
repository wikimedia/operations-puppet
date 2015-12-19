require 'spec_helper'

describe 'bacula::client::mysql_bpipe', :type => :define do
    let(:title) { 'something' }

    context 'with per database' do
        let(:params) { {
            :per_database          => true,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => false,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/for database/) }
    end

    context 'with not per database' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => false,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/alldatabases/) }
    end
    context 'with xtrabackup' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => true,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => false,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/XTRABACKUP/) }
    end

    context 'with is_slave' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => true,
            :mysqldump_innodb_only => false,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/slave/) }
    end

    context 'with innodb_only' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => true,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/single-transcation/) }
    end

    context 'with local_dump_dir' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => true,
            :local_dump_dir        => '/var/backup',
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/\$TEE \$LOCALDUMPDIR/) }
    end
    context 'without local_dump_dir' do
        let(:params) { {
            :per_database          => false,
            :xtrabackup            => false,
            :pigz_level            => 'fast',
            :is_slave              => false,
            :mysqldump_innodb_only => true,
            }
        }
        it { should contain_file('/etc/bacula/scripts/something').with_content(/^[\$TEE \$LOCALDUMPDIR]/) }
    end
end
