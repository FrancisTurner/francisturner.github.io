#!/bin/bash -e
# checkv6cfd.sh
# Copyright (c) 2021, Francis Turner
# All rights reserved.
#
# Script that automates checking and if required downloading and replacing of the 
# latest armv6 cloudflared as built by Darren Hobin (https://github.com/hobindar)
# for use on pi zeros and other armv6 devices


if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


if [ ${1-'--'} = 'DEBUG' ]
then
	echo 'Debug messages enabled'
	DEBUG=true
fi

CFV=`/usr/local/bin/cloudflared --version | /usr/bin/sed 's/.*version \([^ ]*\) .*/\1/'`
if [ '**'$CFV == '**' ] ; then CFV='secfault'; fi
if [ $DEBUG ] ; then echo "CFV = '$CFV'"; fi
URL=`/usr/bin/curl -s https://hobin.ca/cloudflared/ | /usr/bin/sed -n '/href="releases.*tar.gz/ s/.*\(releases[^"]*\).*/\1/p' | head -n 1`
if [ $DEBUG ] ; then echo "URL = $URL"; fi
if echo $URL | /usr/bin/grep -q $CFV 
then
	if [ $DEBUG ] ; then echo "Versions match, already got latest"; fi
else
	echo "Downloading a new one in /tmp/newcf.tgz"
	/usr/bin/curl -s https://hobin.ca/cloudflared/$URL -o /tmp/newcf.tgz
	SHA=`/usr/bin/curl -s https://hobin.ca/cloudflared/ | /usr/bin/sed -n '/readonly value="/ s/.*value="//p' | head -n 1`
	if [ $DEBUG ] ; then echo -e "Checking SHA256 checksum\nShould be: $SHA"; /usr/bin/sha256sum /tmp/newcf.tgz; fi
	if /usr/bin/sha256sum /tmp/newcf.tgz | /usr/bin/grep -q $SHA 
	then
		if [ $DEBUG ] ; then echo "SHA matches so extracting and installing..."; fi
		/usr/bin/tar -C /tmp -xzf /tmp/newcf.tgz
		
		mv /tmp/cloudflared /usr/local/bin
		# if you haven't installed cloudflared as a service then comment next line out
		/usr/bin/systemctl restart cloudflared
	else
		echo "SHA mismatch! not installing, PANIC PANIC PANIC!!!"
		exit 255
	fi
fi
