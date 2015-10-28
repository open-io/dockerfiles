#!/bin/bash
#set -x

### Variables
## Parameters
SPECFILE=${SPECFILE}
SOURCE=${SOURCE}
PATCH=${PATCH}
DISTRIBUTION=${DISTRIBUTION:-epel-7-x86_64}
GIT_COMMIT=${GIT_COMMIT}
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
RPM_OPTIONS=${RPM_OPTIONS}
## Programs
CURL='/usr/bin/curl'
SPECTOOL='/usr/bin/spectool'
RPMBUILD='/usr/bin/rpmbuild'
MOCK='/usr/bin/mock'
GIT='/usr/bin/git'
RPMSPEC='/usr/bin/rpmspec'
AWK='/usr/bin/awk'
CUT='/usr/bin/cut'
TAR='/usr/bin/tar'
RM='/usr/bin/rm'
LS=-'/usr/bin/ls'
## Initializing vars
RPMBUILD_ROOT=~/rpmbuild
SPECFILE_BASENAME=${SPECFILE##*/}
if [ ! -z $SOURCE ]; then
  SOURCE_BASENAME=${SOURCE##*/}
  SOURCE_SUFFIX=${SOURCE//*.}
fi
# Exporting proxies
[ ! -z $HTTP_PROXY ]  && export http_proxy=$HTTP_PROXY
[ ! -z $HTTPS_PROXY ] && export https_proxy=$HTTPS_PROXY
# Using git commit
if [ ! -z $GIT_COMMIT ]; then
  RPM_OPTIONS="$RPM_OPTIONS --define '_with_test 1' --define 'tag $GIT_COMMIT'"
fi

### Functions
log() {
  case $1 in
    'USAGE')
      echo "USAGE: $2"
      exit 1
      ;;
    'WARN'|'NOTICE'|'INFO')
      echo "INFO: $2"
      ;;
    'ERROR'|'ERR')
      echo "ERROR: $2" >&2
      exit 1
      ;;
    *)
      echo "ERROR: Log level '$1'unknown." >&2
      exit 1
  esac
}

program_exists() {
  type "$1" &> /dev/null || \
    log 'ERR' "Program '$1' does not exists."
}

dir_exists() {
  [ -d "$1" ] || \
    log 'ERR' "Directory '$1' does not exists."
}

parse_spec_setup() {
  while getopts "n:cDTb:a:q" opt; do
    case $opt in
      n)
        echo $OPTARG
        ;;
    esac
  done
}

get_spec() {
  eval $RPMSPEC -P $RPM_OPTIONS $RPMBUILD_ROOT/SPECS/$SPECFILE_BASENAME
}

get_tag_from_spec() {
  get_spec | \
    $AWK -v tag=$1 '$0 ~ tag'
}

usage() {
  echo 'docker run -e SPECFILE=URL://domain.com/file.spec --privileged=true --rm openio/rpmbuild'
}

check_parameters() {
  if [ -z "$SPECFILE" ]; then
    log 'USAGE' "$(usage)"
  fi
}

### Preflight checks
check_parameters
program_exists $CURL
program_exists $RPMBUILD
program_exists $MOCK
program_exists $SPECTOOL
program_exists $RPMSPEC
dir_exists "$RPMBUILD_ROOT"
dir_exists "$RPMBUILD_ROOT/SPECS"
dir_exists "$RPMBUILD_ROOT/SOURCES"
dir_exists "$RPMBUILD_ROOT/SRPMS"


### Main
# Download the specfile
$CURL -Ssl $SPECFILE -o $RPMBUILD_ROOT/SPECS/$SPECFILE_BASENAME || \
  log 'ERR' "Failed to download specfile '$specfile'."

# Download the source
if [ ! -z "$SOURCE" ]; then
  case "$SOURCE_SUFFIX" in
    'git')
      program_exists $GIT
      program_exists $AWK
      program_exists $CUT
      program_exists $TAR
      program_exists $RM
      SOURCE0=$(get_tag_from_spec '^Source0')
      [ -z "$SOURCE0" -o $? -ne 0 ] && \
        log 'ERR' "Failed to retrieve SOURCE0 from specfile '$SPECFILE'."
      BUILDDIR=$(parse_spec_setup $(get_spec | $AWK '/^%setup/')
      [ -z "$BUILDDIR" -o $? -ne 0 ] && \
        log 'ERR' "Failed to retrieve source build directory from specfile '$SPECFILE'."
      $GIT clone $SOURCE $RPMBUILD_ROOT/SOURCES/$BUILDDIR || \
        log 'ERR' "Failed to clone git repository '$SOURCE'."
      pushd $RPMBUILD_ROOT/SOURCES
      $TAR cf ${SOURCE0##*/} $BUILDDIR || \
        log 'ERR' "Failed to create archive '${SOURCE0##*/}' from source '$BUILDDIR' after git clone."
      popd
      $RM -rf $RPMBUILD_ROOT/SOURCES/$BUILDDIR
      ;;
    *)
      $CURL -Ssl $SOURCE -o $RPMBUILD_ROOT/SOURCES/$SOURCE_BASENAME || \
        log 'ERR' "Failed to download the source file using curl '$SOURCE'."
      ;;
  esac
fi
# Check and download files using spectool
eval $SPECTOOL -g -S -R $RPM_OPTIONS $RPMBUILD_ROOT/SPECS/$SPECFILE_BASENAME || \
  log 'ERR' "Failed to download the source file using spectool '$SOURCE'."

# Create the SRPM
eval $RPMBUILD -bs --nodeps $RPM_OPTIONS $RPMBUILD_ROOT/SPECS/* || \
  log 'ERR' "Failed to create SRPM."

# Build the package
eval $MOCK -r $DISTRIBUTION $RPM_OPTIONS --rebuild $RPMBUILD_ROOT/SRPMS/* || \
  log 'ERR' "Failed to create packages."

# Upload the resulting packages
$LS -ld /var/lib/mock/*/result/*.rpm

exit 0
