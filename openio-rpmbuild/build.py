#!/usr/bin/python

import os
import re
from git import Repo
import glob
import urlparse
import requests
import tarfile

### Variables
homedir = os.path.expanduser('~')
rpmbuilddir = homedir+'/rpmbuild'
specdir = rpmbuilddir+'/SPECS'
srpmsdir = rpmbuilddir+'/SRPMS'
rpmmacros_path = homedir+'/.rpmmacros'
# Set _sourcedir to _specdir
sourcedir = specdir
specfile = os.environ['SPECFILE']
rpm_options = os.environ.get('RPM_OPTIONS','')
distribution = os.environ.get('DISTRIBUTION','epel-7-x86_64')
specfile_tag = os.environ.get('SPECFILE_TAG')
if specfile_tag:
  rpm_options="--define '_with_test 1' --define 'tag "+specfile_tag+"'"

### Functions
def log_error(msg):
  print 'ERROR: '+msg
  exit(1)

def log_info(msg):
  print 'INFO: '+msg

def log(msg,level='INFO'):
  switch = {
    'INFO':  log_info,
    'ERR':   log_error,
    'ERROR': log_error,
  }
  try:
    switch.get(level)(msg)
  except Exception, e:
    log_error('Failed to log msg '+msg)

def set_sourcedir(rpmmacros_path):
  try:
    log('Setting %_sourcedir to '+sourcedir)
    rpmmacros = open(rpmmacros_path,'w')
    rpmmacros.write('%_sourcedir '+sourcedir+'\n')
    rpmmacros.close()
  except Exception, e:
    log('Failed to set macro %_sourcedir','ERROR')

def get_specfile():
  files = glob.glob(specdir+'/*.spec')
  if files:
    return files[0]
  return False

def is_git(url):
  urlparsed = urlparse.urlparse(url)
  if re.match('.*\.git$',urlparsed.path):
    return True
  else:
    return False

def download_file(url,path):
  try:
    request = requests.get(url, timeout=10, stream=True)
    if request.status_code == 404:
      log('URL '+url+' not found.','ERROR')
    with open(path, 'wb') as fh:
      for chunk in request.iter_content(1024 * 1024):
        fh.write(chunk)
      fh.close()
  except Exception, e:
    log('Failed to download file '+url,'ERROR')

def url_strip_query_fragment(url):
  urlparsed = urlparse.urlparse(url)
  return urlparse.urlunsplit((urlparsed.scheme, urlparsed.netloc, urlparsed.path,'',''))

def git_clone(url,wkdir,branch='master'):
  urlparsed = urlparse.urlparse(url)
  query = urlparse.parse_qs(urlparsed.query)
  if query.get('branch'):
    branch = query['branch'][0]
  if query.get('specdir'):
    global specdir
    new_specdir = specdir+'/'+query['specdir'][0]
    log('Setting specfile workdir to '+new_specdir)
    specdir = new_specdir
  try:
    stripped_url = url_strip_query_fragment(url)
    log('Cloning git repository '+stripped_url)
    repo = Repo.clone_from(stripped_url,wkdir,branch=branch)
  except Exception, e:
    log('Failed to clone git repository '+stripped_url,'ERROR')
  if query.get('commit'):
    commit = query['commit'][0]
    log('Resetting git repository to commid id '+commit)
    try:
      repo.head.reset(commit=commit,index=True)
    except Exception, e:
      log('Failed to reset git repository to commit id '+commit)
  if query.get('archive'):
    archive(output,source,query.get('archive')[0])

def archive(output,source,compression):
  log('Creating archive '+output+' from '+source)
  try:
    with tarfile.open(output,'w:'+compression) as tar:
      tar.add(source,arcname=os.path.basename(source))
  except Exception, e:
    log('Failed to create tar file '+output+' from '+source,'ERROR')

def download(url):
  if is_git(url):
    git_clone(url,specdir)
  else:
    urlparsed = urlparse.urlparse(url)
    download_file(url,specdir+'/'+os.path.basename(urlparsed.path))

def spectool(rpm_options,specfile):
  ret = os.system('/usr/bin/spectool -g -S -R '+rpm_options+' '+specfile)
  if ret != 0:
    log('ERROR','Failed to get source files.')

def rpmbuild_bs(rpm_options,specfile):
  ret = os.system('/usr/bin/rpmbuild -bs --nodeps '+rpm_options+' '+specfile)
  if ret != 0:
    log('ERROR','Failed to create SRPM package.')

def mock(distribution,rpm_options,srpmsdir):
  ret = os.system('/usr/bin/mock -r '+distribution+' '+rpm_options+' --rebuild '+srpmsdir+'/*.src.rpm')
  if ret != 0:
    log('ERROR','Failed to build packages.')

def list_result():
  print glob.glob('/var/lib/mock/*/result/*.rpm')


### Main
set_sourcedir(rpmmacros_path)
# Download the specfile if not already present
if not get_specfile():
  download(specfile)
# Check and download files using spectool
spectool(rpm_options,get_specfile())
# Create the SRPM
rpmbuild_bs(rpm_options,get_specfile())
# Build the package
mock(distribution,rpm_options,srpmsdir)
# List the resulting packages
list_result()
