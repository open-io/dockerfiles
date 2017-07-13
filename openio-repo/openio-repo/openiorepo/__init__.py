#! /usr/bin/env python3
# -*- coding: UTF-8 -*-

'''
This script implements a web application to help create/update a DEB or RPM
repository by uploading packages files (by HTTP POST'ing) to its '/package' URI.

For example like that:

# curl -F 'file=@path/to/package.rpm' \\
       -F 'company=openio' \\
       -F 'prod=sds' \\
       -F 'prod_ver=16.10' \\
       -F 'distro=centos' \\
       -F 'distro_ver=7' \\
       -F 'arch=x86_64' \\
       http://127.0.0.1:5000/package

In addition to the "file" data, you have to pass the following metadata:
 - company
 - prod
 - prod_ver
 - distro
 - distro_ver
 - arch
'''

import os
import sys
import gzip
import shutil
import tempfile
import argparse
import subprocess

import flask
from flask import Flask
from flask import request
from flask import Response

from werkzeug.utils import secure_filename

_APP = Flask(__name__)

_GPG_CMD_BASE = ['gpg', '--batch', '--no-tty']


def error(msg, status=400):
    '''Error reporting helper'''
    err = 'ERROR: ' + msg
    if not err.endswith('\n'):
        err += '\n'
    flask.abort(status, err)
    return err, status, None


@_APP.route('/package', methods=['POST'])
def upload_file():
    '''Handle a package file upload'''

    # pylint: disable=too-many-return-statements

    if request.method == 'POST':
        # Ensure the package file is correctly passed in
        if len(request.files) == 0:
            return error('no request.files')
        if len(request.files) > 1:
            return error('too much files')
        if 'file' not in request.files:
            return error('no "file" in request.files')
        filedesc = request.files['file']
        fname = filedesc.filename
        if fname == '':
            return error('filename is empty')
        # Ensure it is a supported package file
        ext = os.path.splitext(fname)[1][1:]
        if ext not in _APP.config['ALLOWED_EXTENSIONS']:
            return error('file extension rejected')
        # Where are we storing that package
        subdir = get_repo_subdir(request.form, ext)
        if not subdir:
            return error('wrong HTTP request arguments, you must pass: '
                         'company, prod, prod_ver, distro, distro_ver, arch')
        dirname = os.path.join(_APP.config['UPLOAD_FOLDER'], subdir)
        # Ensure target directory exists
        os.makedirs(dirname, exist_ok=True)
        fname = os.path.join(dirname, secure_filename(fname))
        if os.path.exists(fname):
            return error('file already exists in repository: ' + fname)
        filedesc.save(fname)
        # Create / update the repository in the target directory
        ret = True
        if ext == 'deb':
            ret = create_deb_repo(dirname)
        elif ext == 'rpm':
            ret = create_rpm_repo(dirname)
        if not ret:
            return error('Failed to create the repository metadata')
        return 'OK\n'


def get_repo_subdir(req_form, ext):
    '''Get the path subdirectory elements from the request's arguments'''
    company = req_form.get('company', None)
    prod = req_form.get('prod', None)
    prod_ver = req_form.get('prod_ver', None)
    distro = req_form.get('distro', None)
    distro_ver = req_form.get('distro_ver', None)
    arch = req_form.get('arch', None)
    # They must be passed in properly
    if not all((company, prod, prod_ver, distro, distro_ver, arch)):
        return None
    # RPM repositories have separate dirs for the different architectures,
    # DEB repositories have the architecture in the package file name only
    ret = os.path.join(company, prod, prod_ver, distro, distro_ver)
    if ext == 'rpm':
        ret = os.path.join(ret, arch)
    return ret


def run_it(cmd, cwd=None, stdinput=None, stdout=None):
    '''Run a subprocess and handle errors'''
    proc = subprocess.Popen(cmd, cwd=cwd, stdout=stdout, stderr=subprocess.PIPE)
    if stdinput is None:
        _, err = proc.communicate()
    else:
        _, err = proc.communicate(stdinput)

    if proc.returncode != 0:
        _APP.logger.error('ERROR: cannot run: ' + str(cmd))
        _APP.logger.error(err)
        return False
    return True


def create_deb_repo(path):
    '''Create a debian repository, with apt-utils's apt-ftparchive'''
    # Create Packages.* files
    destfn = os.path.join(path, 'Packages')
    cmd = ['apt-ftparchive', 'packages', '.']
    with open(destfn, 'wb') as fout:
        if not run_it(cmd, cwd=path, stdout=fout):
            return False
    with open(destfn, 'rb') as fin, gzip.open(destfn + '.gz', 'wb') as fout:
        shutil.copyfileobj(fin, fout)

    # Create Release.* files
    destfn = os.path.join(path, 'Release')
    cmd = ['apt-ftparchive', 'release', '.']
    with open(destfn, 'wb') as fout:
        if not run_it(cmd, cwd=path, stdout=fout):
            return False
    with open(destfn, 'rb') as fin, gzip.open(destfn + '.gz', 'wb') as fout:
        shutil.copyfileobj(fin, fout)

    # Cleanup, because gpg would bail out otherwise
    inreleasefn = os.path.join(path, 'InRelease')
    if os.path.exists(inreleasefn):
        os.remove(inreleasefn)

    # Create InRelease file:
    cmd = _GPG_CMD_BASE + ['--clearsign', '-o', 'InRelease', 'Release']
    if not run_it(cmd, cwd=path, stdinput=''):
        return False

    # Cleanup , because gpg would bail out otherwise
    releasegpgfn = os.path.join(path, 'Release.gpg')
    if os.path.exists(releasegpgfn):
        os.remove(releasegpgfn)

    # Create Release.gpg file:
    cmd = _GPG_CMD_BASE + ['-abs', '-o', 'Release.gpg', 'Release']
    if not run_it(cmd, cwd=path, stdinput=''):
        return False

    return True


def create_rpm_repo(path):
    '''Create a rpm repository, with createrepo's help'''
    # Create repository metadata (in repodata/repomd.xml)
    cmd = ['createrepo', '--database', '--unique-md-filenames']
    if os.path.exists(os.path.join(path, 'repodata')):
        cmd.append('--update')
        # Cleanup, because gpg would bail out otherwise
        repomd = os.path.join(path, 'repodata', 'repomd.xml.asc')
        if os.path.exists(repomd):
            os.remove(repomd)
    cmd.append(path)
    if not run_it(cmd, cwd=path):
        return False

    # Sign the repository metadata
    cmd = _GPG_CMD_BASE + ['-ab', 'repodata/repomd.xml']
    if not run_it(cmd, cwd=path, stdinput=''):
        return False

    return True


def do_argparse(argv):
    '''Handle CLI arguments'''
    parser = argparse.ArgumentParser(description=__doc__)

    # pylint: disable=bad-continuation

    parser.add_argument('-d', '--destdir',
        default=os.environ.get('OIOREPO_DESTDIR', tempfile.gettempdir()),
        help='Base directory to save uploaded files into')
    parser.add_argument('-m', '--maxlength', default=128 * 1024 * 1024,
        help='Max accepted package file size. Defaults to 128 MB')
    parser.add_argument('-e', '--allowedext', action='append', dest='exts',
        help='Allowed file extentions. Defaults to ".deb" & ".rpm"')

    args = parser.parse_args(argv)
    if not args.exts:
        args.exts = set(['deb', 'rpm'])
    else:
        args.exts = set(args.exts)

    return args


def configure_flask_app(args):
    '''Configure some settings for the Flask framework & app'''
    _APP.config['UPLOAD_FOLDER'] = args.destdir
    _APP.config['MAX_CONTENT_LENGTH'] = args.maxlength
    _APP.config['ALLOWED_EXTENSIONS'] = args.exts


def runnable(cmd):
    '''Make sure we can actually run "cmd" successfully (retcode == 0)'''
    try:
        if not run_it(cmd, stdout=subprocess.DEVNULL):
            return False
    except FileNotFoundError:
        return False
    return True


def prepare(argv=tuple()):
    '''Ensure prerequisites are available: package destination dir & repository
       creation utilities (createrepo & dpkg-scanpackages)
    '''
    args = do_argparse(argv)
    if (not runnable(['createrepo', '--version']) or
            not runnable(['dpkg-scanpackages', '--version'])):
        sys.exit(1)
    os.makedirs(args.destdir, exist_ok=True)
    configure_flask_app(args)


def main(argv=sys.argv[1:]):
    '''Prepare, configure and then starts Flask main loop...'''
    prepare(argv)
    _APP.run()


if __name__ == "__main__":
    main()
else:
    prepare()
