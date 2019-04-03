#!/bin/bash
# parse httpd access_log and extract rpm package list

URL="http://172.16.10.1:5082"
RPMS=$(wget -q -O- $URL/logs/blah.log | sed -e "s/%2B/+/g" | grep -Po "([\w\.\+-]+\.rpm)" | sort | uniq)
for rpm in $RPMS; do
	#cp /var/www/html/bak/$rpm .
	echo $rpm
done
