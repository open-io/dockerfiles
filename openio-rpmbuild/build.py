#! /usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import re
import sys
import glob
import urlparse
import subprocess
import datetime
import tarfile
import shutil

import rpm
import requests

from git import Repo

# Spawned tools binary pathes
_SPECTOOL = '/usr/bin/spectool'
_RPMBUILD = '/usr/bin/rpmbuild'
_RPMSIGN = '/usr/bin/rpmsign'
_MOCK = '/usr/bin/mock'
_GPG = '/usr/bin/gpg'

# Default GPG key ID used to sign packages
_OIO_KEY_ID = 'OpenIO (RPM-GPG-KEY-OPENIO-0) <admin@openio.io>'

# Signing section of ~/.rpmmacros
_RPMMACROS_SIGN = """
%%_signature %s
%%_gpg_name  %s
%%_gpg_path  %%(echo $HOME)/.gnupg
""" % (_GPG, os.environ.get('OIO_KEY_ID', _OIO_KEY_ID))

# Static
homedir = os.path.expanduser('~')
rpmbuilddir = homedir + '/rpmbuild'
specdir = rpmbuilddir + '/SPECS'
sourcedir = specdir
srpmsdir = rpmbuilddir + '/SRPMS'
rpmmacros_path = homedir + '/.rpmmacros'
tmpdir = '/tmp'
gitraw = "https://raw.githubusercontent.com"
github_prefix = "https://github.com/"

# Overridable vars
specfile = os.environ.get('SPECFILE')
sources = os.environ.get('SOURCES', '')
# FIXME: this will fail if embedded spaces are needed, see set_rpm_options()
rpm_options = os.environ.get('RPM_OPTIONS', '').split()
distribution = os.environ.get('DISTRIBUTION', 'epel-7-x86_64')
specfile_tag = os.environ.get('GIT_SRC_TAG')
git_src_repo = os.environ.get('GIT_SRC_REPO')
upload_result = os.environ.get('UPLOAD_RESULT')
keyfile = os.environ.get('OIO_KEYFILE')
repo_name = os.environ.get('GIT_REPO_NAME', 'rpm-specfiles')
branch = os.environ.get('GIT_BRANCH', 'master')
gitremote = os.environ.get('GIT_REMOTE')

verbose = os.environ.get('OIO_BUILD_VERBOSE', False)

gitaccount = 'open-io'
if gitremote:
    if gitremote.startswith(github_prefix):
        urlparsed = urlparse.urlparse(gitremote)
        gitaccount = urlparsed.path.split('/')[1]
    else:
        print 'Only urls starting with: ' + github_prefix + ' are supported'
        exit(1)

# If we're only given a package name, infer the corresponding github url
oio_package = os.environ.get('OIO_PACKAGE')
specfile_url_base = "%s/%s/%s/%s/%s" % (gitraw, gitaccount, repo_name, branch, oio_package)
if not specfile and oio_package:
    specfile = "%s/%s.spec" % (specfile_url_base, oio_package)


def splitext(path):
    '''Variant of os.path.splitext(path) that handles tar file extensions'''
    for ext in ['.tar.gz', '.tar.bz2', '.tar.xz']:
        if path.endswith(ext):
            return path[:-len(ext)], path[-len(ext):]
    return os.path.splitext(path)


def is_url(url):
    '''Determine if `url` is actiually an URL'''
    if (url.startswith('https://') or
            url.startswith('http://') or
            url.startswith('ftp://')):
        return True
    return False


def log(msg, level='INFO'):
    print '%s: %s' % (level, msg)
    if level.startswith('ERR'):
        exit(1)


def logverbose(msg):
    if verbose:
        log(msg)


def os_system(msg, msg_type, *args):
    """
        Execute `*args` as a command line and return status code, then call
        `log(msg, msg_type)` if status is different from 0, i.e. not OK.

        Items can be strings or iterables of strings, everything not empty
    """
    cmd = []
    for arg in args:
        if arg: # Skip empty ones
            if isinstance(arg, str):
                cmd.append(arg)
            else: # Assume an iterable
                cmd.extend(arg)
    logverbose('os_system(...): running %s' % str(cmd))
    ret = subprocess.call(cmd)
    if ret != 0:
        log(msg, msg_type)
    return ret


def set_keyfile():
    """
        Import keyfile into gpg keyring, and setup rpm macros to use this as
        package signing key
    """
    logverbose('set_keyfile()')
    if keyfile and os.path.exists(keyfile):
        msg = "Failed to import the GPG private key, your packages won't be signed."
        ret = os_system(msg, 'INFO', _GPG, '--import', keyfile)
        if ret == 0:
            try:
                log('Setting %_signature')
                with open(rpmmacros_path, 'a') as rpmmacros:
                    rpmmacros.write(_RPMMACROS_SIGN)
                    return True
            except Exception, e:
                log('Failed to set macro %_signature')
                log(str(e), 'ERROR')
    return False


def set_sourcedir(srcdir=sourcedir, macros_path=rpmmacros_path):
    logverbose('set_sourcedir(%s, %s)' % (srcdir, macros_path))
    try:
        with open(macros_path, 'w') as rpmmacros:
            rpmmacros.write('%_sourcedir ' + srcdir + '\n')
        log('Setting %_sourcedir to ' + srcdir)
    except Exception:
        log('Failed to set macro %_sourcedir', 'ERROR')


def get_specfile():
    files = glob.glob(specdir + '/*.spec')
    if files:
        return files[0]
    return False


def is_git(url):
    return re.match('.*\\.git$', urlparse.urlparse(url).path)


def download_file(url, path):
    logverbose('download_file(%s, %s)' % (url, path))
    try:
        request = requests.get(url, timeout=10, stream=True)
        if request.status_code == 404:
            log('URL ' + url + ' not found.', 'ERROR')
        with open(path, 'wb') as fh:
            for chunk in request.iter_content(1024 * 1024):
                fh.write(chunk)
    except Exception:
        log('Failed to download file ' + url, 'ERROR')


def url_strip_query_fragment(url):
    urlparsed = urlparse.urlparse(url)
    return urlparse.urlunsplit((urlparsed.scheme, urlparsed.netloc, urlparsed.path, '', ''))


def git_clone(url, destdir, branch='master', commit=None, clean=True, archive=None, arcname=None):
    logverbose('git_clone(...)')
    try:
        log('Cloning git repository ' + url)
        urlparsed = urlparse.urlparse(url)
        wkdir = tmpdir + '/' + os.path.basename(urlparsed.path)
        repo = Repo.clone_from(url, wkdir, branch=branch)
    except Exception, e:
        log('Failed to clone git repository ' + url)
        log('Exception :' + str(e), 'ERROR')
    if commit:
        try:
            log('Resetting git repository to commid id ' + commit)
            repo.head.reset(commit=commit, index=True)
        except Exception, e:
            log('Failed to reset git repository to commit id ' + commit)
            log('Exception :' + str(e), 'ERROR')
    if clean:
        clean_git_repo(wkdir)
    if archive:
        if not arcname:
            arcname = splitext(archive)[0]
        create_archive(destdir + '/' + archive, wkdir, arcname)
    else:
        for filename in glob.glob(wkdir + '/*'):
            try:
                shutil.move(filename, destdir)
            except Exception, e:
                log('Failed to copy file ' + filename + ' to ' + destdir)
                log('Exception :' + str(e), 'ERROR')


def clean_git_repo(directory):
    logverbose('clean_git_repo(%s)' % directory)
    try:
        shutil.rmtree(directory + '/.git')
        os.remove(directory + '/.gitignore')
    except Exception:
        log('Failed to remove git files in ' + directory)


def create_archive(archive, source, arcname=None, clean=True):
    logverbose('create_archive(%s, %s, %s, %s)' % (archive, source, str(arcname), str(clean)))
    try:
        compression = os.path.splitext(archive)[1][1:]
        if not arcname:
            arcname = splitext(archive)[0]
        log('Creating archive ' + archive + ' with compression ' + compression)
        with tarfile.open(archive, 'w:' + compression) as tar:
            tar.add(source, arcname=arcname)
    except Exception, e:
        log('Failed to create tar file ' + archive + ' from ' + source)
        log('Exception :' + str(e), 'ERROR')
    if clean:
        try:
            shutil.rmtree(source)
        except Exception:
            log('Failed to remove directory ' + source)


def set_specdir(spcdir=''):
    logverbose('set_specdir(%s)' % spcdir)
    global specdir
    if spcdir:
        spcdir = '/' + spcdir
    new_specdir = rpmbuilddir + '/SPECS' + spcdir
    if specdir == sourcedir:
        set_sourcedir(new_specdir)
    log('Setting specfile workdir to ' + new_specdir)
    specdir = new_specdir


def download_specfile(url, directory):
    logverbose('download_specfile(%s, %s)' % (url, directory))
    urlparsed = urlparse.urlparse(url)
    query = urlparse.parse_qs(urlparsed.query)
    stripped_url = url_strip_query_fragment(url)
    if query.get('branch'):
        branch = query['branch'][0]
    else:
        branch = 'master'
    if query.get('specdir'):
        set_specdir(query['specdir'][0])
    if is_git(stripped_url):
        git_clone(stripped_url, directory, branch)
    else:
        download_file(stripped_url, directory + '/' + os.path.basename(urlparsed.path))


def set_rpm_options():
    logverbose('set_rpm_options()')
    if specfile_tag and git_src_repo:
        global rpm_options
        rpm_options = ["--define", "_with_test 1", "--define", "tag %s" % specfile_tag, '--define', 'git_repo %s' % git_src_repo]
        logverbose('Setting RPM options: ' + str(rpm_options))


def get_rpmts():
    logverbose('get_rpmts()')
    if specfile_tag:
        rpm.addMacro('_with_test', '1')
        rpm.addMacro('tag', specfile_tag)
        rpm.addMacro('git_repo', git_src_repo)
    return rpm.TransactionSet()


def download_sources():
    logverbose('download_sources()')
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
                specsource = os.path.basename(spec.sourceHeader['SOURCE'][i])
                if query.get('arcname'):
                    arcname = query['arcname'][0]
                else:
                    arcname = splitext(specsource)[0]
                git_clone(stripped_url, sourcedir, branch, commit, archive=specsource, arcname=arcname)
            else:
                download_file(stripped_url, sourcedir + '/' + os.path.basename(urlparsed.path))


def get_companion_sources(local_specfile):
    """
        Download local "SourceXX" files specified in the specfile, if they are not
        an URL, i.e. they are located in the same location as the specfile itself
    """
    logverbose('get_companion_sources(%s)' % local_specfile)
    # Use spectool to list files, handling "%{...}" macro substitutions properly
    cmd = [_SPECTOOL, '--list-files', local_specfile]
    output = subprocess.check_output(cmd)

    # Match "SourceXX:" or "PatchXXXX:" lines from specfile
    re_source = re.compile(r'^\s*(Source|Patch)(?P<srcnum>\d*)\s*:\s*(?P<srcloc>.+)\s*$')

    for line in output.splitlines():
        rem = re_source.match(line.strip())
        if rem:
            srcloc = rem.group('srcloc')
            if not is_url(srcloc):
                download_file(specfile_url_base + '/' + srcloc, specdir + '/' + srcloc)
        else:
            log("Warning: get_companion_sources(): line does not match: " + line)


def spectool(rpm_options, specfile):
    logverbose('spectool(%s, %s)' % (rpm_options, specfile))
    msg = 'Failed to get source files.'
    os_system(msg, 'ERROR', _SPECTOOL, '-g', '-S', '-R', rpm_options, specfile)


def rpmbuild_bs(rpm_options, specfile):
    logverbose('rpmbuild_bs(%s, %s)' % (rpm_options, specfile))
    msg = 'Failed to create SRPM package.'
    os_system(msg, 'ERROR', _RPMBUILD, '-bs', '--nodeps', rpm_options, specfile)


def get_repo_data():
    today = datetime.date.today()
    return {
        'company': os.environ.get('OIO_COMPANY', 'openio'),
        'prod': os.environ.get('OIO_PROD', 'sds'),
        'prod_ver': os.environ.get('OIO_PROD_VER', today.strftime("%y.%m")),
        'distro': os.environ.get('OIO_DISTRO', 'centos'),
        'distro_ver': os.environ.get('OIO_DISTRO_VER', '7'),
        'arch': os.environ.get('OIO_ARCH', 'x86_64'),
        'repo_host': os.environ.get('OIO_REPO_HOST', 'mirror2.openio.io'),
        'repo_port': os.environ.get('OIO_REPO_PORT', '80'),
    }


re_mock_root = re.compile(r"config_opts\['root'\] = '(?P<mockroot>[^']+)'")


def patch_mock_config(distribution, upload_result):
    '''
        Replace the baseurl in the mock configuration file pointing to the openio
        mirror, so that it points to the currently being populated one.
        This allows mock to find newly built packages that are depended upon.
    '''
    logverbose('patch_mock_config(%s, %s)' % (distribution, upload_result))
    mock_cfg = '/etc/mock/' + distribution + '.cfg'
    newlines = []
    mockroot = None
    with open(mock_cfg, 'rb') as fin:
        lines = fin.readlines()
        for line in lines:
            if upload_result and line.startswith('baseurl=http://mirror.openio.io'):
                # FIXME: currently only doing this if uploading to oiorepo
                repodata = get_repo_data()
                newlines.append('baseurl=http://%(repo_host)s:%(repo_port)s/pub/repo/%(company)s/%(prod)s/%(prod_ver)s/%(distro)s/%(distro_ver)s/%(arch)s/\n' % repodata)
            else:
                rem = re_mock_root.match(line)
                if rem:
                    mockroot = rem.group('mockroot')
                newlines.append(line)
    if not os.path.exists('/home/builder/.config'):
        os.mkdir('/home/builder/.config')
    # Overrides global config with local one
    with open('/home/builder/.config/mock.cfg', 'wb') as fout:
        fout.writelines(newlines)
    return mockroot


def mock(distribution, rpm_options, srpmsdir, upload_result):
    logverbose('mock(%s, %s, %s, %s)' % (distribution, rpm_options, srpmsdir, upload_result))
    srpms = glob.glob(srpmsdir + '/*.src.rpm')
    msg = 'Failed to build packages.'
    os_system(msg, 'ERROR', _MOCK, '-r', distribution, rpm_options, '--rebuild', srpms)


def sign_rpms(rpmfiles):
    logverbose('sign_rpms(%s)' % rpmfiles)
    msg = 'Failed to sign packages.'
    os_system(msg, 'ERROR', _RPMSIGN, '--addsign', rpmfiles)


def upload_http(url, rpmfiles):
    '''
        Upload packages to an oiorepo web application:
        http://${OIO_REPO_HOST}:${OIO_REPO_PORT}/package
    '''
    logverbose('upload_http(%s, %s)' % (url, rpmfiles))
    urlparsed = urlparse.urlparse(url)
    if urlparsed.scheme != 'http':
        log('Cannot upload files using http since URI seems not to be a http protocol: %s' % urlparsed.scheme, 'ERROR')

    for lpath in rpmfiles:
        with open(lpath, "rb") as fin:
            files = {"file": fin}
            data = get_repo_data()
            ret = requests.post(url, files=files, data=data)
            if ret.status_code != requests.codes.ok:
                log('Cannot upload package: ' + os.path.basename(lpath))
                log('to oiorepo: ' + url)
                log('Parameters for oiorepo web app: ' + str(data))
                log('request.status_code: ' + str(ret.status_code))
                log('request.text:')
                log(ret.text)
                ret.raise_for_status()


def main():
    set_rpm_options()
    set_specdir()
    set_sourcedir()
    key_ok = set_keyfile()
    # Download the specfile if not already present
    if not get_specfile():
        download_specfile(specfile, specdir)
    # Download additionnal sources
    download_sources()
    # Check and download files using spectool
    spectool(rpm_options, get_specfile())
    # Download "SourceXX" files located alongside the specfile
    local_specfile = specdir + '/' + os.path.basename(specfile)
    get_companion_sources(local_specfile)
    # Create the SRPM
    rpmbuild_bs(rpm_options, get_specfile())
    # Patch mock configuration
    mockroot = patch_mock_config(distribution, upload_result)
    mockresults = '/var/lib/mock/' + mockroot + '/result'
    # Build the package
    mock(distribution, rpm_options, srpmsdir, upload_result)
    # Output mock log files (so that they can be archived by StackStorm)
    for mlf in glob.glob(mockresults + '/*.log'):
        log('Mock log file: ' + mlf)
        with open(mlf, 'rb') as fin:
            sys.stdout.write(fin.read())
    # Find the resulting packages
    rpmfiles = glob.glob(mockresults + '/*.rpm')
    # List the resulting packages
    log('Listing generated files:')
    for path in rpmfiles:
        log('- ' + path)
    # Sign the packages
    if key_ok:
        sign_rpms(rpmfiles)
    # Upload the packages to oiorepo web service
    if upload_result:
        upload_http(upload_result, rpmfiles)


if __name__ == "__main__":
    main()
