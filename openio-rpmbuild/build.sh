#!/bin/bash

### Variables
RPMBUILD_ROOT=~/rpmbuild
#SRPM=http://mirror.openio.io/pub/repo/stable/openio/sds/centos/7/common/SRPM/python-oiopy-0.4.0-1.el7.oio.src.rpm
#SOURCE=https://pypi.python.org/packages/source/o/oiopy/oiopy-0.4.0.tar.gz
#SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/a27350e7a8abab724cc6a7e3086d2b8e30b7984b/python-oiopy/python-oiopy.spec
DISTRIBUTION=${DISTRIBUTION:-epel-7-x86_64}
#REGEXP_URL='https?://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

### Main
if [ -z $DISTRIBUTION ]; then
  echo "Error: You must specify a distribution using the DISTRIBUTION environment variable."
  exit 1
fi

if [ ! -z $SRPM ]; then

  # Using existing SRPM
  SRPM_BASENAME=$(/usr/bin/basename $SRPM)
  /usr/bin/curl -Ssl $SRPM -o $RPMBUILD_ROOT/SRPMS/$SRPM_BASENAME || \
  ( echo "Error: Failed to download SRPM file $SRPM" ; exit 1 )

else

# Rebuild SRPM from SPECFILE
if [ -z $SPECFILE ]; then
  echo "Error: You must specify a specfile using the SPECFILE environment variable."
  exit 1
fi
SPECFILE_BASENAME=$(/usr/bin/basename $SPECFILE)
/usr/bin/curl -Ssl $SPECFILE -o $RPMBUILD_ROOT/SPECS/$SPECFILE_BASENAME || \
  ( echo "Error: Failed to download spec file $SPECFILE" ; exit 1 )
if [ ! -z $SOURCE ]; then
  SOURCE_BASENAME=$(/usr/bin/basename $SOURCE)
  /usr/bin/curl -Ssl $SOURCE -o $RPMBUILD_ROOT/SOURCES/$SOURCE_BASENAME || \
    ( echo "Error: Failed to download source file $SOURCE" ; exit 1 )
else
  /usr/bin/spectool -g -S -R $RPMBUILD_ROOT/SPECS/* || \
  ( echo "Error: Failed to download source file defined in spec file." ; exit 1 )
fi
# Build SRPM
/usr/bin/rpmbuild -bs --nodeps $RPMBUILD_ROOT/SPECS/* || \
  ( echo "Error: Failed to build SRPM." ; exit 1 )

fi

# Build packages using Mock
/usr/bin/mock -r $DISTRIBUTION --rebuild $RPMBUILD_ROOT/SRPMS/* || \
  ( echo "Error: Failed to build package." ; exit 1 )
