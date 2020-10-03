#!/bin/sh

systemctl stop phd
puppet agent --disable
