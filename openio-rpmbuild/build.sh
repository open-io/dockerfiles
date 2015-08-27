RPMBUILD_ROOT=~/rpmbuild
SOURCE=${SOURCE:-https://pypi.python.org/packages/source/o/oiopy/oiopy-0.4.0.tar.gz}
SOURCE_BASENAME=$(basename $SOURCE)
SPECFILE=${SPECFILE:-https://raw.githubusercontent.com/open-io/rpm-specfiles/a27350e7a8abab724cc6a7e3086d2b8e30b7984b/python-oiopy/python-oiopy.spec}
SPECFILE_BASENAME=$(basename $SPECFILE)
DISTRIBUTION=${DISTRIBUTION:-epel-7-x86_64}

curl -Ssl $SOURCE -o $RPMBUILD_ROOT/SOURCES/$SOURCE_BASENAME && curl -Ssl $SPECFILE -o $RPMBUILD_ROOT/SPECS/$SPECFILE_BASENAME && rpmbuild -bs --nodeps $RPMBUILD_ROOT/SPECS/* && /usr/bin/mock -r $DISTRIBUTION --rebuild $RPMBUILD_ROOT/SRPMS/*
