require 'spec_helper'

describe Puppet::Type.type(:ssh_authorized_key), unless: Puppet.features.microsoft_windows? do
  include PuppetSpec::Files

  before(:each) do
    provider_class = class_double('Puppet::Provider::SshAuthorizedKey', name: 'fake', suitable?: true, supports_parameter?: true)
    allow(described_class).to receive(:defaultprovider).and_return(provider_class)
    allow(described_class).to receive(:provider).and_return(provider_class)

    provider = instance_double('Puppet::Provider::SshAuthorizedKey', class: provider_class, file_path: make_absolute('/tmp/whatever'), clear: nil)
    allow(provider_class).to receive(:new).and_return(provider)
  end

  it 'has :name as its namevar' do
    expect(described_class.key_attributes).to eq [:name]
  end

  describe 'when validating attributes' do
    [:name, :provider, :drop_privileges].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq :param
      end
    end

    [:type, :key, :user, :target, :options, :ensure].each do |property|
      it "has a #{property} property" do
        expect(described_class.attrtype(property)).to eq :property
      end
    end
  end

  describe 'when validating values' do
    describe 'for name' do
      it 'supports valid names' do
        described_class.new(name: 'username', ensure: :present, user: 'nobody')
        described_class.new(name: 'username@hostname', ensure: :present, user: 'nobody')
      end

      it 'supports whitespace' do
        described_class.new(name: 'my test', ensure: :present, user: 'nobody')
      end
    end

    describe 'for ensure' do
      it 'supports :present' do
        described_class.new(name: 'whev', ensure: :present, user: 'nobody')
      end

      it 'supports :absent' do
        described_class.new(name: 'whev', ensure: :absent, user: 'nobody')
      end

      it 'nots support other values' do
        expect { described_class.new(name: 'whev', ensure: :foo, user: 'nobody') }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end

    describe 'for drop_privileges' do
      it 'uses true as a default value' do
        expect(described_class.new(name: 'whev', user: 'nobody')[:drop_privileges]).to eq true
      end

      [true, :true, 'true', :yes, 'yes'].each do |value|
        it "supports #{value} and returns a boolean true" do
          expect(described_class.new(name: 'whev', user: 'nobody', drop_privileges: value)[:drop_privileges]).to eq true
        end
      end

      [false, :false, 'false', :no, 'no'].each do |value|
        it "supports #{value} and returns a boolean false" do
          expect(described_class.new(name: 'whev', user: 'nobody', drop_privileges: value)[:drop_privileges]).to eq false
        end
      end

      it 'raises an exception on something else' do
        expect { described_class.new(name: 'whev', user: 'nobody', drop_privileges: 'nope') }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end

    describe 'for type' do
      [
        :'ssh-dss', :dsa,
        :'ssh-rsa', :rsa,
        :'ecdsa-sha2-nistp256',
        :'ecdsa-sha2-nistp384',
        :'ecdsa-sha2-nistp521',
        :ed25519, :'ssh-ed25519',
        :'ecdsa-sk', :'sk-ecdsa-sha2-nistp256@openssh.com',
        :'ed25519-sk', :'sk-ssh-ed25519@openssh.com',
        :'ssh-rsa-cert-v01@openssh.com',
        :'ssh-ed25519-cert-v01@openssh.com',
        :'ssh-dss-cert-v01@openssh.com',
        :'ecdsa-sha2-nistp256-cert-v01@openssh.com',
        :'ecdsa-sha2-nistp384-cert-v01@openssh.com',
        :'ecdsa-sha2-nistp521-cert-v01@openssh.com'
      ].each do |keytype|
        it "supports #{keytype}" do
          described_class.new(name: 'whev', type: keytype, user: 'nobody')
        end
      end

      it 'aliases :rsa to :ssh-rsa' do
        key = described_class.new(name: 'whev', type: :rsa, user: 'nobody')
        expect(key.should(:type)).to eq :'ssh-rsa'
      end

      it 'aliases :dsa to :ssh-dss' do
        key = described_class.new(name: 'whev', type: :dsa, user: 'nobody')
        expect(key.should(:type)).to eq :'ssh-dss'
      end

      it 'aliases :ecdsa-sk to :sk-ecdsa-sha2-nistp256@openssh.com' do
        key = described_class.new(name: 'whev', type: :'ecdsa-sk', user: 'nobody')
        expect(key.should(:type)).to eq :'sk-ecdsa-sha2-nistp256@openssh.com'
      end

      it 'aliases :ed25519-sk to :sk-ssh-ed25519@openssh.com' do
        key = described_class.new(name: 'whev', type: :'ed25519-sk', user: 'nobody')
        expect(key.should(:type)).to eq :'sk-ssh-ed25519@openssh.com'
      end

      it "doesn't support values other than ssh-dss, ssh-rsa, dsa, rsa" do
        expect { described_class.new(name: 'whev', type: :something) }.to raise_error(Puppet::Error, %r{Invalid value})
      end
    end

    describe 'for key' do
      # rubocop:disable Layout/LineLength
      it 'supports a valid key like a 1024 bit rsa key' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', key: 'AAAAB3NzaC1yc2EAAAADAQABAAAAgQDCPfzW2ry7XvMc6E5Kj2e5fF/YofhKEvsNMUogR3PGL/HCIcBlsEjKisrY0aYgD8Ikp7ZidpXLbz5dBsmPy8hJiBWs5px9ZQrB/EOQAwXljvj69EyhEoGawmxQMtYw+OAIKHLJYRuk1QiHAMHLp5piqem8ZCV2mLb9AsJ6f7zUVw==') }.not_to raise_error
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid key like a 4096 bit rsa key' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', key: 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDEY4pZFyzSfRc9wVWI3DfkgT/EL033UZm/7x1M+d+lBD00qcpkZ6CPT7lD3Z+vylQlJ5S8Wcw6C5Smt6okZWY2WXA9RCjNJMIHQbJAzwuQwgnwU/1VMy9YPp0tNVslg0sUUgpXb13WW4mYhwxyGmIVLJnUrjrQmIFhtfHsJAH8ZVqCWaxKgzUoC/YIu1u1ScH93lEdoBPLlwm6J0aiM7KWXRb7Oq1nEDZtug1zpX5lhgkQWrs0BwceqpUbY+n9sqeHU5e7DCyX/yEIzoPRW2fe2Gx1Iq6JKM/5NNlFfaW8rGxh3Z3S1NpzPHTRjw8js3IeGiV+OPFoaTtM1LsWgPDSBlzIdyTbSQR7gKh0qWYCNV/7qILEfa0yIFB5wIo4667iSPZw2pNgESVtenm8uXyoJdk8iWQ4mecdoposV/znknNb2GPgH+n/2vme4btZ0Sl1A6rev22GQjVgbWOn8zaDglJ2vgCN1UAwmq41RXprPxENGeLnWQppTnibhsngu0VFllZR5kvSIMlekLRSOFLFt92vfd+tk9hZIiKm9exxcbVCGGQPsf6dZ27rTOmg0xM2Sm4J6RRKuz79HQgA4Eg18+bqRP7j/itb89DmtXEtoZFAsEJw8IgIfeGGDtHTkfAlAC92mtK8byeaxGq57XCTKbO/r5gcOMElZHy1AcB8kw==') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid key like a 1024 bit dsa key' do
        expect { described_class.new(name: 'whev', type: :dsa, user: 'nobody', key: 'AAAAB3NzaC1kc3MAAACBAI80iR78QCgpO4WabVqHHdEDigOjUEHwIjYHIubR/7u7DYrXY+e+TUmZ0CVGkiwB/0yLHK5dix3Y/bpj8ZiWCIhFeunnXccOdE4rq5sT2V3l1p6WP33RpyVYbLmeuHHl5VQ1CecMlca24nHhKpfh6TO/FIwkMjghHBfJIhXK+0w/AAAAFQDYzLupuMY5uz+GVrcP+Kgd8YqMmwAAAIB3SVN71whLWjFPNTqGyyIlMy50624UfNOaH4REwO+Of3wm/cE6eP8n75vzTwQGBpJX3BPaBGW1S1Zp/DpTOxhCSAwZzAwyf4WgW7YyAOdxN3EwTDJZeyiyjWMAOjW9/AOWt9gtKg0kqaylbMHD4kfiIhBzo31ZY81twUzAfN7angAAAIBfva8sTSDUGKsWWIXkdbVdvM4X14K4gFdy0ZJVzaVOtZ6alysW6UQypnsl6jfnbKvsZ0tFgvcX/CPyqNY/gMR9lyh/TCZ4XQcbqeqYPuceGehz+jL5vArfqsW2fJYFzgCcklmr/VxtP5h6J/T0c9YcDgc/xIfWdZAlznOnphI/FA==') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ssh-rsa-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ssh-rsa-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAHHNzaC1yc2EtY2VydC12MDFAb3BlbnNzaC5jb20AAAAg07B03uArzrZbW5YYiH8y+mT5NNjbKOfDVz13rBPyiDAAAAADAQABAAABgQCltzNwldRtt+sn0EXx9IMPeeoGRQUpOD2KyLW7BfJSf+40SJnsVE4MkuH1WiJnow9nwhTMtBEIkx7ocqw6bBXxrXmnqMV50DbLYZiEVz1UDRdXx5RMnNb3bbmmsyf/doNeyDjiIHAwNM4cSyUppTwLw3sU/YcdeNSBbFcUDt5dJpZw6OjiD+V3OTdvpbmBeG7sftNM6871SRmNyc2T79bwG0QxBd1XMMwgK8ZjRkCPDLVl63Jy1vbV00mT65Gd+2enSC9Lb63XHS9ixZQ+vPqn9cw8ESNq3M3tNMvLUj4HdjopaEO8CAMMIjXWIJz8oOPUGWu2oFkSpWAo9r/lW+ox6s1QGbjp0l86Ve9KybHpaVKkWn9wJUDqcF04n82PHYJFs0srn397iN5FC/DHpviEBmT/GAzLeqnslf2f9lGXA/UleVE6fI3WUwlzcEgIy6rrozxh4lEPe7f5CqDIkjv6cIrid9StzqBPQE7U10yjlr/U3EKYajv5Il7gIg/qRaMAAAAAAAAAAAAAAAIAAAAQaG9zdC5leGFtcGxlLmNvbQAAABQAAAAQaG9zdC5leGFtcGxlLmNvbQAAAABfLFAkAAAAAGEMMoEAAAAAAAAAAAAAAAAAAAGXAAAAB3NzaC1yc2EAAAADAQABAAABgQCltzNwldRtt+sn0EXx9IMPeeoGRQUpOD2KyLW7BfJSf+40SJnsVE4MkuH1WiJnow9nwhTMtBEIkx7ocqw6bBXxrXmnqMV50DbLYZiEVz1UDRdXx5RMnNb3bbmmsyf/doNeyDjiIHAwNM4cSyUppTwLw3sU/YcdeNSBbFcUDt5dJpZw6OjiD+V3OTdvpbmBeG7sftNM6871SRmNyc2T79bwG0QxBd1XMMwgK8ZjRkCPDLVl63Jy1vbV00mT65Gd+2enSC9Lb63XHS9ixZQ+vPqn9cw8ESNq3M3tNMvLUj4HdjopaEO8CAMMIjXWIJz8oOPUGWu2oFkSpWAo9r/lW+ox6s1QGbjp0l86Ve9KybHpaVKkWn9wJUDqcF04n82PHYJFs0srn397iN5FC/DHpviEBmT/GAzLeqnslf2f9lGXA/UleVE6fI3WUwlzcEgIy6rrozxh4lEPe7f5CqDIkjv6cIrid9StzqBPQE7U10yjlr/U3EKYajv5Il7gIg/qRaMAAAGUAAAADHJzYS1zaGEyLTUxMgAAAYAdrQYxs/y/eYGBLQJIDQkCN5MumF3s14rpivxdkow6hc3fClLiVF0KE8viyENPpYmhUMOPFqpm/acCz9ueP1kigHw1P8la2E7FFDyAOveD8qLE+y2MigjRq1ZGzc8C4mjZutA3v+MO2Jxa+X9ZBs99wYDfAsD/3LeNFQfHJK7PlxZCFF//ZOkOfR3nLHyIWF1XHLzZlXgM5pQbsrrZF2I0VCU+BhsBI0gBrmvSflEgBlZqCipChGPBaRybK+OLa4rUq+HzCnHsaJ3KMri8aN5TMlMd2tZPq3ZaaaBRgg67nqm7B76c0kBI9vApB4KvvPxReJTAL9YUMXRzrNLSxbraQXhx8JYKEyIad1o4TXqKZBj+qzpR0L+w8RGkNZ+OhJiisP5WMuR1oTgZNPqNYDmpU84GAnzXgdjR5NpTxneQPRGD8SfRC+RsNqI5Vs5J5n5Ap5MoqlttiY86C+Ofe4/6GVIWVQuDpSMzhaRbgEVj4XxT9VLuDSWy8/l85UxKkQ8=') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ssh-ed25519-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ssh-ed25519-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAIHNzaC1lZDI1NTE5LWNlcnQtdjAxQG9wZW5zc2guY29tAAAAII03FWZnj5mlByzlCf6DrreuQ1xd4P06OpWVtTv1LA8tAAAAIAELyKZcNagkQdfPc484zFekxiBOfkTYW5WQp8ZEQ0yRAAAAAAAAAAAAAAACAAAAEGhvc3QuZXhhbXBsZS5jb20AAAAUAAAAEGhvc3QuZXhhbXBsZS5jb20AAAAAXyxVTAAAAABhDDeOAAAAAAAAAAAAAAAAAAAAMwAAAAtzc2gtZWQyNTUxOQAAACABC8imXDWoJEHXz3OPOMxXpMYgTn5E2FuVkKfGRENMkQAAAFMAAAALc3NoLWVkMjU1MTkAAABAMeOkwGO8xK4xLWXemAtcwyFkBT+I57PdBI9Y+6r2MpU8WqpvY8BpR8eohwzrSyTaxt/SeRrrQ+npfMY1g2z5DA==') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ssh-dss-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ssh-dss-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAHHNzaC1kc3MtY2VydC12MDFAb3BlbnNzaC5jb20AAAAgcCc5I4UIAZWRjnkQx/IiMadlKaM8AncxZnEepHrJU7QAAACBAK+gMKBIurFf2QdcVgf+PVJBJlGcC61ej2pFSaZURhgcyhAzf0PAxWwWmeSb5m89PXy09Q4ufDV/iDTKCLV2/tM/fk8Nqk8zT8R92SCdVLy5mN7q8seFhrDeZ1zsWRU6nQHFYiwoS0VhtMyGp1J39mX7wJqbdnIuG/1cqhB4Lxh7AAAAFQDPYY2uOe2WOrQQQY50KUjsUUdrrwAAAIBOio9RBHQasCGAuXGczY2ORp3P0rsUlPR7pLJ9C1+wN1tLfTmOkn9iNmRR3O1xButRs1gBkhlTz7zRreWHOtcXOEoZmj1wIvPqFdmvKv4KX5krq2Dd6vcmTO1LW5CZXvlPM5hYK+IE5+bER1K68xjDIIZfiM0tEmBhnME8nXENeAAAAIEAlHywsFzvdR8VP3acZSHdy82iiKslTn1fOeS10uk+qYZXP7NOhUf+b9WhGSCcv3IzlCGSHs5ClfmABBWUDJyOxF3Fwlmx1z/detbJYgrSBc6bzrqqofac7pWjf3lN7pB/bX4zpN27BjIUwDxYvLRdHlrwA5vZTN98187wOt7D1cwAAAAAAAAAAAAAAAIAAAAQaG9zdC5leGFtcGxlLmNvbQAAABQAAAAQaG9zdC5leGFtcGxlLmNvbQAAAABfLFZ4AAAAAGEMOLkAAAAAAAAAAAAAAAAAAAGyAAAAB3NzaC1kc3MAAACBAK+gMKBIurFf2QdcVgf+PVJBJlGcC61ej2pFSaZURhgcyhAzf0PAxWwWmeSb5m89PXy09Q4ufDV/iDTKCLV2/tM/fk8Nqk8zT8R92SCdVLy5mN7q8seFhrDeZ1zsWRU6nQHFYiwoS0VhtMyGp1J39mX7wJqbdnIuG/1cqhB4Lxh7AAAAFQDPYY2uOe2WOrQQQY50KUjsUUdrrwAAAIBOio9RBHQasCGAuXGczY2ORp3P0rsUlPR7pLJ9C1+wN1tLfTmOkn9iNmRR3O1xButRs1gBkhlTz7zRreWHOtcXOEoZmj1wIvPqFdmvKv4KX5krq2Dd6vcmTO1LW5CZXvlPM5hYK+IE5+bER1K68xjDIIZfiM0tEmBhnME8nXENeAAAAIEAlHywsFzvdR8VP3acZSHdy82iiKslTn1fOeS10uk+qYZXP7NOhUf+b9WhGSCcv3IzlCGSHs5ClfmABBWUDJyOxF3Fwlmx1z/detbJYgrSBc6bzrqqofac7pWjf3lN7pB/bX4zpN27BjIUwDxYvLRdHlrwA5vZTN98187wOt7D1cwAAAA3AAAAB3NzaC1kc3MAAAAoqdL2M2Q5R6xBk1mym3GrtmF7EbAh0PX0LiQ78c4+eQaWHJ71cEIe6A==') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ecdsa-sha2-nistp256-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ecdsa-sha2-nistp256-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAKGVjZHNhLXNoYTItbmlzdHAyNTYtY2VydC12MDFAb3BlbnNzaC5jb20AAAAgQUGk9Pzd+RqECXZMmgj8bFEumUGfZPEhJhyUusF7hvwAAAAIbmlzdHAyNTYAAABBBBmo/Yw8pVDSObTkJxlpYL5s9tVnpj7ubeky+PKY2zJ8pRYIHS3XJ6x/NyB/iFoYlGxrn4CaMPwNvYxvSEdTj60AAAAAAAAAAAAAAAIAAAAQaG9zdC5leGFtcGxlLmNvbQAAABQAAAAQaG9zdC5leGFtcGxlLmNvbQAAAABfLFfgAAAAAGEMOkIAAAAAAAAAAAAAAAAAAABoAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBmo/Yw8pVDSObTkJxlpYL5s9tVnpj7ubeky+PKY2zJ8pRYIHS3XJ6x/NyB/iFoYlGxrn4CaMPwNvYxvSEdTj60AAABjAAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAABIAAAAIGkErINcPm1MpBhKuUmdR0KAPJGZCSeGT9E6FafcVhlFAAAAIERD5WsflI5QdJETz3n64tIDcdPbUF0GQW8iP8EV+Nf5') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ecdsa-sha2-nistp384-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ecdsa-sha2-nistp384-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAKGVjZHNhLXNoYTItbmlzdHAzODQtY2VydC12MDFAb3BlbnNzaC5jb20AAAAgh+/K6gv7WlwX9qVlKLH8Vurzo5xfc8/glVcT7auQOhIAAAAIbmlzdHAzODQAAABhBDouPHnR+OD4jfdqMbhFXTfB8vTjpZYLQSl0HxEXRAs8AgqDEZI1lJEVwdxtJUbczyu1Wj7wM45YpSpgUQVU38rmVkpxujqhhMMmqMWf87gnjm9oVLLFvJHdauKNnXjJQQAAAAAAAAAAAAAAAgAAABBob3N0LmV4YW1wbGUuY29tAAAAFAAAABBob3N0LmV4YW1wbGUuY29tAAAAAF8sWnQAAAAAYQw85wAAAAAAAAAAAAAAAAAAAIgAAAATZWNkc2Etc2hhMi1uaXN0cDM4NAAAAAhuaXN0cDM4NAAAAGEEOi48edH44PiN92oxuEVdN8Hy9OOllgtBKXQfERdECzwCCoMRkjWUkRXB3G0lRtzPK7VaPvAzjlilKmBRBVTfyuZWSnG6OqGEwyaoxZ/zuCeOb2hUssW8kd1q4o2deMlBAAAAgwAAABNlY2RzYS1zaGEyLW5pc3RwMzg0AAAAaAAAADBJccfmOaYjNVbqkx0X7cLpl53EzTAMdv9k159mBLYaepMnLYmhKx+LvfA5bAUTar4AAAAwSO7n770NIdhhMZjGio4GKDyKq2WW6QLRXleY6QcynBaQ90rkMVnt+jeIEs30h6F8') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it 'supports a valid ecdsa-sha2-nistp521-cert-v01@openssh.com key' do
        expect { described_class.new(name: 'bastelfreakwashere', type: :'ecdsa-sha2-nistp521-cert-v01@openssh.com', user: 'opensshrulez', key: 'AAAAKGVjZHNhLXNoYTItbmlzdHA1MjEtY2VydC12MDFAb3BlbnNzaC5jb20AAAAg2xMe+Z9AuETNwM88pTDRpEtKbGRarajtZ5UaxSmmaQoAAAAIbmlzdHA1MjEAAACFBAFGg1vGsCq5kEzivd0s/kf0x5/TDzb0DwPzGz5YRsUtDlhT7+F7r2lVRvEEXCagc/UjTisIQ0kcG4IgMoI3VsaFEAHrBgF4whI/bhh6i+WzIHnT3NWkjqhdX+kLBXtlm+uFXyslmFlda4gGmjGeHvsDHgC2rN7cSuGh//3DBXtelkB+uQAAAAAAAAAAAAAAAgAAABBob3N0LmV4YW1wbGUuY29tAAAAFAAAABBob3N0LmV4YW1wbGUuY29tAAAAAF8sW9wAAAAAYQw+QgAAAAAAAAAAAAAAAAAAAKwAAAATZWNkc2Etc2hhMi1uaXN0cDUyMQAAAAhuaXN0cDUyMQAAAIUEAUaDW8awKrmQTOK93Sz+R/THn9MPNvQPA/MbPlhGxS0OWFPv4XuvaVVG8QRcJqBz9SNOKwhDSRwbgiAygjdWxoUQAesGAXjCEj9uGHqL5bMgedPc1aSOqF1f6QsFe2Wb64VfKyWYWV1riAaaMZ4e+wMeALas3txK4aH//cMFe16WQH65AAAApwAAABNlY2RzYS1zaGEyLW5pc3RwNTIxAAAAjAAAAEIA92a8QL5J/EMxRaKh9fSysTaEyyN/3KesBC8tI1rwytKILtfrcAIGxXtDQF6eZ72BWUvu6aqHIM6pmIHlnpzsROgAAABCAJHPzoeANenL8ZdlEf0jz8aEiGlGt02Z+vzsajQakKclFL4P8Nm5fojR2Mo2C45CQfO+kfkRQM1UUfDrVZcPzN0S') }.not_to raise_error # rubocop:disable Layout/LineLength
      end
      # rubocop:enable Layout/LineLength

      it "doesn't support whitespaces" do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', key: 'AAA FA==') }.to raise_error(Puppet::Error, %r{Key must not contain whitespace})
      end
    end

    describe 'for options' do
      it 'supports flags as options' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'cert-authority') }.not_to raise_error
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'no-port-forwarding') }.not_to raise_error
      end

      it 'supports key-value pairs as options' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'command="command"') }.not_to raise_error
      end

      it 'supports key-value pairs where value consist of multiple items' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'from="*.domain1,host1.domain2"') }.not_to raise_error
      end

      it 'supports environments as options' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'environment="NAME=value"') }.not_to raise_error
      end

      it 'supports multiple options as an array' do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: ['cert-authority', 'environment="NAME=value"']) }.not_to raise_error
      end

      it "doesn't support a comma separated list" do
        expect { described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: 'cert-authority,no-port-forwarding') }.to raise_error(Puppet::Error, %r{must be provided as an array})
      end

      it 'uses :absent as a default value' do
        expect(described_class.new(name: 'whev', type: :rsa, user: 'nobody').should(:options)).to eq [:absent]
      end

      it 'property should return well formed string of arrays from is_to_s' do
        resource = described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: ['a', 'b', 'c'])
        str = (Puppet.version.to_f < 5.0) ? ['a', 'b', 'c'] : "['a', 'b', 'c']"
        expect(resource.property(:options).is_to_s(['a', 'b', 'c'])).to eq(str)
      end

      it 'property should return well formed string of arrays from should_to_s' do
        resource = described_class.new(name: 'whev', type: :rsa, user: 'nobody', options: ['a', 'b', 'c'])
        str = (Puppet.version.to_f < 5.0) ? 'a b c' : "['a', 'b', 'c']"
        expect(resource.property(:options).should_to_s(['a', 'b', 'c'])).to eq(str)
      end
    end

    describe 'for user' do
      it 'supports present users' do
        described_class.new(name: 'whev', type: :rsa, user: 'root')
      end

      it 'supports absent users' do
        described_class.new(name: 'whev', type: :rsa, user: 'ihopeimabsent')
      end
    end

    describe 'for target' do
      it 'supports absolute paths' do
        described_class.new(name: 'whev', type: :rsa, target: '/tmp/here')
      end

      it "uses the user's path if not explicitly specified" do
        expect(described_class.new(name: 'whev', user: 'root').should(:target)).to eq File.expand_path('~root/.ssh/authorized_keys')
      end

      it "doesn't consider the user's path if explicitly specified" do
        expect(described_class.new(name: 'whev', user: 'root', target: '/tmp/here').should(:target)).to eq '/tmp/here'
      end

      it 'informs about an absent user' do
        Puppet::Log.level = :debug
        logs = []
        Puppet::Util::Log.with_destination(Puppet::Test::LogCollector.new(logs)) do
          described_class.new(name: 'whev', user: 'idontexist').should(:target)
        end
        expect(logs.map(&:message)).to include('The required user is not yet present on the system')
      end
    end
  end

  describe 'when neither user nor target is specified' do
    it 'raises an error' do
      expect {
        described_class.new(
          name: 'Test',
          key: 'AAA',
          type: 'ssh-rsa',
          ensure: :present,
        )
      }.to raise_error(Puppet::Error, %r{user.*or.*target.*mandatory})
    end
  end

  describe 'when both target and user are specified' do
    it 'uses target' do
      resource = described_class.new(
        name: 'Test',
        user: 'root',
        target: '/tmp/blah',
      )
      expect(resource.should(:target)).to eq '/tmp/blah'
    end
  end

  describe 'when user is specified' do
    it 'determines target' do
      resource = described_class.new(
        name: 'Test',
        user: 'root',
      )
      target = File.expand_path('~root/.ssh/authorized_keys')
      expect(resource.should(:target)).to eq target
    end

    # Bug #2124 - ssh_authorized_key always changes target if target is not defined
    it "doesn't raise spurious change events" do
      resource = described_class.new(name: 'Test', user: 'root')
      target = File.expand_path('~root/.ssh/authorized_keys')
      expect(resource.property(:target).safe_insync?(target)).to eq true
    end
  end

  describe 'when calling validate' do
    it "doesn't crash on a non-existent user" do
      resource = described_class.new(
        name: 'Test',
        user: 'ihopesuchuserdoesnotexist',
      )
      resource.validate
    end
  end
end
