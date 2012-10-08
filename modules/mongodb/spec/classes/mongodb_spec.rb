require 'spec_helper'

describe 'mongodb', :type => :class do

  describe 'when deploying on debian' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
        :lsbdistcodename => 'sid',
      }
    end

    describe 'by default' do
      it {
        should_not contain_class('mongodb::sources::apt')
        should_not contain_apt__source('10gen')
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb'
        })
        should contain_file('/etc/mongod.conf')
        should contain_service('mongodb').with({
          :name => 'mongodb'
        })
      }
    end

    describe 'when enabling 10gen repo' do
      let :params do
        { :enable_10gen => true,
          :init => 'sysv' }
      end

      it {
        should contain_apt__source('10gen').with({
          :location => 'http://downloads-distro.mongodb.org/repo/debian-sysvinit',
        })
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb-10gen'
        })
      }
    end

    describe 'when overriding location' do

      let :params do
        { :enable_10gen => true,
          :location => 'http://myrepo' }
      end

      it {
        should contain_class('mongodb::sources::apt')
        should contain_apt__source('10gen').with({
          :location => 'http://myrepo'
        })
      }
    end
  end

  describe 'when deploying on ubuntu' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
        :lsbdistcodename => 'edgy',
      }
    end

    describe 'by default' do
      it {
        should_not contain_class('mongodb::sources::apt')
        should_not contain_apt__source('10gen')
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb'
        })
        should contain_file('/etc/mongod.conf')
        should contain_service('mongodb').with({
          :name => 'mongodb'
        })
      }
    end

    describe 'when enabling 10gen repo on ubuntu' do
      let :params do
        { :enable_10gen => true }
      end

      it {
        should contain_class('mongodb::sources::apt')
        should contain_apt__source('10gen').with({
          :location => 'http://downloads-distro.mongodb.org/repo/ubuntu-upstart',
        })
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb-10gen'
        })
      }
    end

    describe 'when overriding init' do
      let :params do
        { :enable_10gen => true,
          :init => 'sysv' }
      end

      it {
        should contain_class('mongodb::sources::apt')
        should contain_apt__source('10gen').with({
          :location => 'http://downloads-distro.mongodb.org/repo/debian-sysvinit'
        })
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb-10gen'
        })
      }
    end

    describe 'when using custom location' do
      let :params do
        { :enable_10gen => true,
          :location => 'http://myrepo' }
      end

      it {
        should contain_class('mongodb::sources::apt')
        should contain_apt__source('10gen').with({
          :location => 'http://myrepo'
        })
      }
    end
  end

  describe 'when deploying on redhat' do
    let :facts do
      {
        :osfamily        => 'RedHat',
        :lsbdistcodename => 'Final',
      }
    end

    describe 'by default' do
      it {
        should_not contain_class('mongodb::sources::yum')
        should_not contain_yumrepo('10gen')
        should contain_package('mongodb-10gen').with({
          :name => 'mongodb-server'
        })
        should contain_file('/etc/mongod.conf')
        should contain_service('mongodb').with({
          :name => 'mongod'
        })
      }
    end

    describe 'when using 10gen source' do
      let :params do
        { :enable_10gen => true }
      end

      it {
        should contain_class('mongodb::sources::yum')
        should contain_package('mongodb-10gen').with({
          :name => 'mongo-10gen-server'
        })
        should contain_file('/etc/mongod.conf')
        should contain_service('mongodb').with({
          :name => 'mongod'
        })
      }
    end
  end

  describe 'when deploying on Solaris' do
    let :facts do
      { :osfamily        => 'Solaris' }
    end
    it { expect { should raise_error(Puppet::Error) } }
  end

end
