class salt::master::key(
    $salt_master_pubkey_type='prod',
    $salt_master_privkey=secret('salt/master/master.pem'),
){
    $salt_master_pubkey = {
      'prod' => "-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvBJHjkRCQ/zxMnjWXX9/
nhJEmzvOlW7yGfJSuv9HmbUCqOY4gB33FcRdSOYtR1Z4QfWM67bwwknhzPH4IcgS
m2Ewf12P3BMQy5c8yRt3obSVSHTxVRnVAAPxkB+zN9mXGRclz/ooGcCPJYPgHnSM
VXS02il2BC9zwdt4pf/qHP0ML06mPWn9thPgZ3Bq5wo95sCds0vmKxp3JLios8w0
WwdhclnfBVtqwJnl78Y4REnCOpLQ0xWxF9XyS5e3CHd9vPDd0kJiRD4cg3NbHbMQ
6JGIwZT0fPutGQMOBWWH0GE0SvkmgAyutf7ndezsAakKh4Yp8sYT2Q7LDKr7pKkx
EE8UMQreWtLUBo0MFbmEPaJu/kXdBRdtzcu77dofst39HqbplxuPYBHQKntCh2T1
77Ct2kVA0Y8YGw/K/ojlTWWdUdRgzhJlX14A2jWAdjoUsXHI77ChJE5mIBWcYTKD
og71XJb2b1KenxsBOPWIJKixjEgCtTLnn4H+bMZtCcezGeyOU+QqzW3rKu+d0Z2V
jyc5hxBS94pc0EQK3q0HeWShC4ilrhuYa5irzNnXGI8e4azfiJt0mUVClXOhnIZD
/J/CnwYj0NOCWK4k6CzHPz//WsTMn6i2pf/Ys9vDLoKjk8EHY2/zqn3CutsNN60k
 MKYDznRvmD47IY3/8fvhWE8CAwEAAQ==
-----END PUBLIC KEY-----",
      'labs' => "-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA030L1ZeU2/aUnDnm8rdg
wXhs7PRdmXalCx1YXTsIVY/NqFI+LsqENrOp7kM4+R2VN9ch3buQN1X5iqpuK4AG
QGwIkoheH6Btcb2diRYGugQvR6qdt1N/Z2SEs3JW4wveFCW69Mz7OjVOt656ZnBk
IkChgqvHfc7/df5Td8gzoJgM3qP7JfNCL58e05ba/Szw3T1Ucrusx6hVVk7MVNXt
bFkSyAlI0Qplaq3VhRE4X8XNUkj1xlsNJ0+kCSe6iDHYHLM9S0dtD93FDz8lZAMx
f4iV9IFFf1RV54+EpMdIxJlmwxBiMVbJZg8xnjOGgS7Ff+hORfK2lxIkG2TpsKJi
A89TdGbUnzbiafbsyNA7uCUUAc6s2Cxho/1ujryFtEH7KiltpTyF3WG8bRJ6kp+9
/ZD1Kgg1dYu2+TVEvohok52hRPjS9QRB6uaMc18WfA7LvJiATHIhL2F5yu7mN9NN
LngQ6z6gcUPlXENBmpPO4XTOIQrJXd33oLIBvQSqPsVPrxZoymDNhvfvxGPLGTB+
ofxMu9dsmhvqMb5mPEPFBPiqsjpip9wvtEJrqv39iqWFHLRgX3s/UDIDVTxZS9zx
4D99u6/HmjTwFGFZxdVhagZ8dxvX3YSOFdA3JaqNb4nyoB/G1oC/xtstXJGbjxGj
Z9Tp7NpKVjKDut1WC23F55ECAwEAAQ==
      -----END PUBLIC KEY-----",
    }

    file { '/etc/salt/pki/master/master.pub':
        content => $salt_master_pubkey[$salt_master_pubkey_type],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['salt-master'],
    }

    file { '/etc/salt/pki/master/master.pem':
        content => $salt_master_privkey,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['salt-master'],
    }
}
