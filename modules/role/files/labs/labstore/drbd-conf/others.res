resource others {

  on labstore1004 {
    device    /dev/drbd3;
    address   10.64.37.19:7790;
    disk      /dev/misc/others;
    meta-disk internal;
  }

  on labstore1005 {
    device    /dev/drbd3;
    address   10.64.37.20:7790;
    disk      /dev/misc/others;
    meta-disk internal;
  }
}
