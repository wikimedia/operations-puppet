require 'spec_helper'

describe 'logrotate::rule', :type => :define do
    let(:title) { 'some_rule' }

    context 'undef periodicity is allowed' do
        let(:params) { {
            :periodicity => :undef,
            :file_glob => '/var/log/some.log',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule') }
    end

    context 'invalid periodicity' do
        let(:params) { {
            :periodicity => 'invalid',
            :file_glob => '/var/log/some.log',
        } }
        it { should raise_error(Puppet::Error, /periodicity should be in/) }
    end

    context 'undef periodicity and size' do
        let(:params) { {
            :periodicity => :undef,
            :file_glob => '/var/log/some.log',
            :size => '10M',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .with_content(/\ssize 10M/)
        }
    end

    context 'defined periodicity and size' do
        let(:params) { {
            :periodicity => 'daily',
            :file_glob => '/var/log/some.log',
            :size => '10M',
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .with_content(/maxsize 10M/)
        }
    end

    context 'defined periodicity and no size' do
        let(:params) { {
            :periodicity => 'daily',
            :file_glob => '/var/log/some.log',
            :size => :undef,
        } }
        it { should contain_file('/etc/logrotate.d/some_rule')
                        .without_content(/size/)
        }
    end
end
