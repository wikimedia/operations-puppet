require 'spec_helper'

describe 'bacula::director::fileset', :type => :define do
    let(:title) { 'something' }
    let(:params) { { :includes => ["/", "/var",], } }

    it 'should create /etc/bacula/conf.d/fileset-something.conf' do
        should contain_file('/etc/bacula/conf.d/fileset-something.conf').with({
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'bacula',
            'mode'    => '0440',
        })
    end

    context 'without excludes' do
        it 'should create valid content for /etc/bacula/conf.d/fileset-something.conf' do
            should contain_file('/etc/bacula/conf.d/fileset-something.conf') \
            .with_content(/File = \//) \
            .with_content(/File = \/var/)
        end
    end

    context 'with excludes' do
        let(:params) { {
            :includes    => ["/", "/var",],
            :excludes    => ["/tmp",],
            }
        }
        it 'should create valid content for /etc/bacula/conf.d/fileset-something.conf' do
            should contain_file('/etc/bacula/conf.d/fileset-something.conf') \
            .with_content(/File = \//) \
            .with_content(/File = \/var/) \
            .with_content(/File = \/tmp/)
        end
    end
end
