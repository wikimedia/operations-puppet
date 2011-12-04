# mc.pp

# Virtual resource for midnight commander

class mc {
        package { mc:
                ensure => "latest";
        }

}
