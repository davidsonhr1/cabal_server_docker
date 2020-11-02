#!/bin/sh

docker run -itd -p 1433:1433 --privileged --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v sql1:/var/opt/mssql cabaldocker