#!/bin/bash

systemctl stop phd
puppet agent --disable
