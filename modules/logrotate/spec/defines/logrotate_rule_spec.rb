require 'spec_helper'

describe 'logrotate::rule' do
    let(:title) { 'some_rule' }

    context 'undef frequency is allowed' do
        let(:params) { {
            :frequency => :undef,
            :file_glob => '/var/log/some.log',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule') }
    end

    context 'invalid frequency' do
        let(:params) { {
            :frequency => 'invalid',
            :file_glob => '/var/log/some.log',
        } }
        it { should raise_error(Puppet::Error, /frequency should be in/) }
    end

    context 'undef frequency and size' do
        let(:params) { {
            :frequency => :undef,
            :file_glob => '/var/log/some.log',
            :size => '10M',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .with_content(/\ssize 10M/)
        }
    end

    context 'defined frequency and size' do
        let(:params) { {
            :frequency => 'daily',
            :file_glob => '/var/log/some.log',
            :size => '10M',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .with_content(/maxsize 10M/)
        }
    end

    context 'defined frequency and no size' do
        let(:params) { {
            :frequency => 'daily',
            :file_glob => '/var/log/some.log',
            :size => :undef,
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .without_content(/size/)
        }
    end
end
