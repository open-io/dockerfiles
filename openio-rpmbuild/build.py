#!/usr/bin/python

import os
import re
from git import Repo
import glob
import urlparse
import requests
import tarfile
import shutil
import rpm

### Variables
# Static
homedir = os.path.expanduser('~')
rpmbuilddir = homedir+'/rpmbuild'
specdir = rpmbuilddir+'/SPECS'
srpmsdir = rpmbuilddir+'/SRPMS'
rpmmacros_path = homedir+'/.rpmmacros'
tmpdir = '/tmp'
# Set _sourcedir to _specdir
# Overridable vars
sourcedir = specdir
specfile = os.environ.get('SPECFILE')
sources = os.environ.get('SOURCES','')
rpm_options = os.environ.get('RPM_OPTIONS','')
distribution = os.environ.get('DISTRIBUTION','epel-7-x86_64')
specfile_tag = os.environ.get('SPECFILE_TAG')

### Functions
def usage():
  print 'Usage: SPECFILE=http://example.com/myspecfile.spec build.py'

# Redefine splitext for tar files
def splitext(path):
  for ext in ['.tar.gz','.tar.bz2','.tar.xz']:
    if path.endswith(ext):
      return path[:-len(ext)], path[-len(ext):]
  return os.path.splitext(path)

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
    log('Downloading file '+url)
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

def git_clone(url,destdir,branch='master',commit=None,clean=True,archive=None,arcname=None):
  try:
    log('Cloning git repository '+url)
    urlparsed = urlparse.urlparse(url)
    wkdir = tmpdir+'/'+os.path.basename(urlparsed.path)
    repo = Repo.clone_from(url,wkdir,branch=branch)
  except Exception, e:
    log('===== '+str(e),'ERROR')
    log('Failed to clone git repository '+url,'ERROR')
  if commit:
    try:
      log('Resetting git repository to commid id '+commit)
      repo.head.reset(commit=commit,index=True)
    except Exception, e:
      log('===== '+str(e),'ERROR')
      log('Failed to reset git repository to commit id '+commit)
  if clean:
    clean_git_repo(wkdir)
  if archive:
    if not arcname:
      arcname = splitext(archive)[0]
    create_archive(destdir+'/'+archive,wkdir,arcname)

def clean_git_repo(directory):
  try:
    shutil.rmtree(directory+'/.git')
    os.remove(directory+'/.gitignore')
  except Exception, e:
    log('Failed to remove git files in '+directory)


def create_archive(archive,source,arcname=None,clean=True):
  try:
    compression = os.path.splitext(archive)[1][1:]
    if not arcname:
      arcname = splitext(archive)[0]
    log('Creating archive '+archive+' with compression '+compression)
    with tarfile.open(archive,'w:'+compression) as tar:
      tar.add(source,arcname=arcname)
  except Exception, e:
    log('===== '+str(e),'ERROR')
    log('Failed to create tar file '+archive+' from '+source,'ERROR')
  if clean:
    try:
      shutil.rmtree(source)
    except Exception, e:
      log('Failed to remove directory '+source)

def download_specfile(url,directory):
  urlparsed = urlparse.urlparse(url)
  query = urlparse.parse_qs(urlparsed.query)
  stripped_url = url_strip_query_fragment(url)
  if query.get('branch'):
    branch = query['branch'][0]
  if query.get('specdir'):
    global specdir
    new_specdir = specdir+'/'+query['specdir'][0]
    log('Setting specfile workdir to '+new_specdir)
    specdir = new_specdir
  if is_git(stripped_url):
    git_clone(stripped_url,directory,branch)
  else:
    download_file(stripped_url,directory+'/'+os.path.basename(urlparsed.path))

def set_rpm_options():
  if specfile_tag:
    global rpm_options
    rpm_options = "--define '_with_test 1' --define 'tag "+specfile_tag+"'"

def get_rpmts():
  if specfile_tag:
    rpm.addMacro('_with_test','1')
    rpm.addMacro('tag',specfile_tag)
  return rpm.TransactionSet()

def download_sources():
  if sources:
    sources_list = sources.split(' ')
    for i, url in enumerate(sources_list):
      if not url:
        continue
      urlparsed = urlparse.urlparse(url)
      query = urlparse.parse_qs(urlparsed.query)
      stripped_url = url_strip_query_fragment(url)
      if is_git(stripped_url):
        if query.get('branch'):
          branch = query['branch'][0]
        else:
          branch = 'master'
        if query.get('commit'):
          commit = query['commit'][0]
        else:
          commit = None
        spec = get_rpmts().parseSpec(get_specfile())
        specsource = spec.sourceHeader['SOURCE'][i]
        if query.get('arcname'):
          arcname = query['arcname'][0]
        else:
          arcname = splitext(os.path.basename(specsource))[0]
        git_clone(stripped_url,sourcedir,branch,commit,archive=os.path.basename(specsource),arcname=arcname)
      else:
        download_file(stripped_url,directory+'/'+os.path.basename(urlparsed.path))

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
set_rpm_options()
set_sourcedir(rpmmacros_path)
# Download the specfile if not already present
if not get_specfile():
  download_specfile(specfile,specdir)
# Check and download files using spectool
#download_sources(sources,sourcedir)
download_sources()
spectool(rpm_options,get_specfile())
# Create the SRPM
rpmbuild_bs(rpm_options,get_specfile())
# Build the package
mock(distribution,rpm_options,srpmsdir)
# List the resulting packages
list_result()
