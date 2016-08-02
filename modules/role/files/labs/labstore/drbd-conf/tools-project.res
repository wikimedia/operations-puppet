resource tools-project {

  on labstore1004 {
    device    /dev/drbd2;
    address   10.64.37.19:7789;
    disk      /dev/tools-project/tools-project;
    meta-disk internal;
  }

  on labstore1005 {
    device    /dev/drbd2;
    address   10.64.37.20:7789;
    disk      /dev/tools-project/tools-project;
    meta-disk internal;
  }
}
