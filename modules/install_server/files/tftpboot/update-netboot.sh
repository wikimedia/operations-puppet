#!/bin/sh

ORIGPWD=$PWD
WD=`mktemp -d`

cd $WD

export http_proxy=http://webproxy.eqiad.wmnet:8080
#wget http://d-i.debian.org/daily-images/amd64/daily/netboot/netboot.tar.gz
#wget http://ftp.us.debian.org/debian/dists/jessie/main/installer-amd64/current/images/netboot/netboot.tar.gz
wget http://mirrors.wikimedia.org/debian/dists/stable/main/installer-amd64/current/images/netboot/netboot.tar.gz
mkdir jessie-installer
tar -C jessie-installer -zxf netboot.tar.gz

# T90236 / Debian #765577
#mkdir initrd-extract
#cd initrd-extract
#fakeroot /bin/sh -c "
#zcat ../jessie-installer/debian-installer/amd64/initrd.gz | cpio -id
#cp $ORIGPWD/write_net_rules lib/udev/
#find . | cpio --quiet -o -H newc | gzip -9 > ../jessie-installer/debian-installer/amd64/initrd.gz
#"
#cd ..

# add non-free firmware to the image
wget http://cdimage.debian.org/cdimage/unofficial/non-free/firmware/jessie/current/firmware.tar.gz
mkdir firmware
tar -C firmware -zxf firmware.tar.gz
pax -x sv4cpio -s'%firmware%/firmware%' -w firmware | gzip -c >firmware.cpio.gz
cat firmware.cpio.gz >> jessie-installer/debian-installer/amd64/initrd.gz

mv jessie-installer $ORIGPWD
cd $ORIGPWD
rm -rf $WD

sudo rm -rf /var/lib/puppet/volatile/tftpboot/jessie-installer
sudo mv jessie-installer /var/lib/puppet/volatile/tftpboot/
sudo chown -R root:root /var/lib/puppet/volatile/tftpboot/jessie-installer
