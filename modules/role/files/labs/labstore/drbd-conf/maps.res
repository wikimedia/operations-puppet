resource maps {

  on labstore1004 {
    device    /dev/drbd1;
    address   10.64.37.19:7788;
    disk      /dev/misc/maps;
    meta-disk internal;
  }

  on labstore1005 {
    device    /dev/drbd1;
    address   10.64.37.20:7788;
    disk      /dev/misc/maps;
    meta-disk internal;
  }
}
