#!/bin/bash
#set -x

### Variables
## Parameters
SPECFILE=${SPECFILE}
#SPECFILE=url#commit
#SPECFILE=url?branch
SPECFILE_TAG=${SPECFILE_TAG}
SOURCE=${SOURCE}
PATCH=${PATCH}
DISTRIBUTION=${DISTRIBUTION:-epel-7-x86_64}
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
LS='/usr/bin/ls'
## Initializing vars
RPMBUILD_ROOT=~/rpmbuild
SPECDIR=${SPECDIR:-$RPMBUILD_ROOT/SPECS}
# Spec var
if [ ! -z $SPECFILE ]; then
  # Detect git commit option
  if [ "$SPECFILE" != "${SPECFILE//*#}" ]; then
    SPECFILE_COMMIT=${SPECFILE//*#}
    [ ! -z "$SPECFILE_COMMIT" ] && \
      SPECFILE=${SPECFILE//#*}
  fi
  # Detect git branch option
  if [ "$SPECFILE" != "${SPECFILE//*\?}" ]; then
    SPECFILE_BRANCH=${SPECFILE//*\?}
    [ ! -z "$SPECFILE_BRANCH" ] && \
      SPECFILE=${SPECFILE//\?*}
  fi
  SPECFILE_BASENAME=${SPECFILE##*/}
  SPECFILE_SUFFIX=${SPECFILE//*.}
fi
SPECFILE_BASENAME=${SPECFILE##*/}
# Source var
if [ ! -z $SOURCE ]; then
  SOURCE_BASENAME=${SOURCE##*/}
  SOURCE_SUFFIX=${SOURCE//*.}
fi
# Exporting proxies
[ ! -z $HTTP_PROXY ]  && \
  export http_proxy=$HTTP_PROXY
[ ! -z $HTTPS_PROXY ] && \
  export https_proxy=$HTTPS_PROXY
# Using git commit
if [ ! -z "$SPECFILE_TAG" ]; then
  RPM_OPTIONS="$RPM_OPTIONS --define '_with_test 1' --define 'tag $SPECFILE_TAG'"
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
  eval $RPMSPEC -P $RPM_OPTIONS $SPECDIR/$SPECFILE_BASENAME
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

curl_download() {
  $CURL -Ssl $1 -o $2 || \
    log 'ERR' "Failed to download file '$1' to '$2' using curl."
}

is_git() {
  $GIT ls-remote "$1" >/dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    log 'ERR' "Unable to read git repository '$1'"
    exit 1;
  fi
}

git_clone() {
  GIT_OPTIONS=''
  while getopts "b:c:" opt; do
    case $opt in
      b)
        GIT_OPTIONS="-b $OPTARG --single-branch"
        ;;
      c)
        GIT_COMMIT="$OPTARG"
        ;;
    esac
  done
  shift $((OPTIND-1))
  $GIT clone $GIT_OPTIONS $1 $2 || \
    log 'ERR' "Failed to clone git repository '$1' to '$2'."
  ls -ld $2/*
  # Going to the commit
  if [ ! -z "$GIT_COMMIT" ]; then
    pushd $2
    $GIT reset --hard $GIT_COMMIT || \
      log 'ERR' "Failed to switch to commit id '$GIT_COMMIT'."
    popd
  fi
}

git_archive() {
  git_clone $1 $2
  pushd $(dirname $2)
  $TAR cf $3 $2 || \
    log 'ERR' "Failed to create archive '${3##*/}' from source '$2' after git clone."
  popd
  $RM -rf $RPMBUILD_ROOT/SOURCES/$BUILDDIR
}

# Fedora set sourcedir to specdir
# Its much easier to manage each repositories
set_sourcedir_to_specdir() {
  echo "%_sourcedir $SPECDIR" \
     >~/.rpmmacros
}

### Preflight checks
check_parameters
program_exists $CURL
program_exists $RPMBUILD
program_exists $MOCK
program_exists $SPECTOOL
program_exists $RPMSPEC
dir_exists "$RPMBUILD_ROOT"
dir_exists "$SPECDIR"
dir_exists "$RPMBUILD_ROOT/SOURCES"
dir_exists "$RPMBUILD_ROOT/SRPMS"


### Main
set_sourcedir_to_specdir
# Download the specfile
case "$SPECFILE_SUFFIX" in
  'git')
    [ ! -z "$SPECFILE_BRANCH" ] && \
      GIT_OPTIONS="-b $SPECFILE_BRANCH"
    [ ! -z "$SPECFILE_COMMIT" ] && \
      GIT_OPTIONS="$GIT_OPTIONS -c $SPECFILE_COMMIT"
    git_clone $GIT_OPTIONS "$SPECFILE" "$SPECDIR"
    ;;
  *)
    curl_download "$SPECFILE" "$SPECDIR/$SPECFILE_BASENAME"
    ;;
esac

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
      ########
      git_archive "$SOURCE" "$RPMBUILD_ROOT/SOURCES/$BUILDDIR" "$SOURCE0"
      ########
      ;;
    *)
      curl_download "$SOURCE" "$RPMBUILD_ROOT/SOURCES/$SOURCE_BASENAME"
      ;;
  esac
fi
# Check and download files using spectool
eval $SPECTOOL -g -S -R $RPM_OPTIONS $SPECDIR/*.spec || \
  log 'ERR' "Failed to download the source file using spectool '$SOURCE'."

# Create the SRPM
eval $RPMBUILD -bs --nodeps $RPM_OPTIONS $SPECDIR/*.spec || \
  log 'ERR' "Failed to create SRPM."

# Build the package
eval $MOCK -r $DISTRIBUTION $RPM_OPTIONS --rebuild $RPMBUILD_ROOT/SRPMS/*.src.rpm || \
  log 'ERR' "Failed to create packages."

# List the resulting packages
$LS -ld /var/lib/mock/*/result/*.rpm

exit 0
