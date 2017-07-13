#! /usr/bin/env python3
# -*- coding: UTF-8 -*-

'''
Sample/test code to send a file, should be equivalent to:

curl -F 'file=@package-3.2.3-1.el7.oio.x86_64.rpm' \\
     -F 'company=openio' \\
     -F 'prod=sds' \\
     -F 'prod_ver=16.10' \\
     -F 'distro=centos' \\
     -F 'distro_ver=7' \\
     -F 'arch=x86_64' \\
     http://127.0.0.1:5000/package
'''

import sys
import argparse

import requests

_DEFAULT_OIOREPO_URL = 'http://127.0.0.1:5000/package'

def do_argparse(argv):
    '''Handle CLI arguments'''
    # pylint: disable=bad-continuation

    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('-u', '--url', default=_DEFAULT_OIOREPO_URL,
        help='URL of the oiorepo Flask web application')

    parser.add_argument('-f', '--filename', required=True,
        help='Package filename to be sent')

    parser.add_argument('--company', default='openio',
        help='Company that produced the package')
    parser.add_argument('--prod', default='sds',
        help='Product the package is part of')
    parser.add_argument('--prod_ver', required=True,
        help='Product version')
    parser.add_argument('--distro', required=True,
        help='Linux distribution the package is for')
    parser.add_argument('--distro_ver', required=True,
        help='Supported distribution version')
    parser.add_argument('--arch', required=True,
        help='Supported hardwawre architecture')

    args = parser.parse_args(argv)
    return args

def main(argv=sys.argv[1:]):
    '''
        Send a file with its accompanying parameters to an oiorepo Flask web
        application
    '''
    args = do_argparse(argv)
    data = {
        'company': args.company,
        'prod': args.prod,
        'prod_ver': args.prod_ver,
        'distro': args.distro,
        'distro_ver': args.distro_ver,
        'arch': args.arch,
    }

    with open(args.filename, "rb") as fin:
        files = {"file": fin}
        ret = requests.post(args.url, files=files, data=data)
        print(ret)

if __name__ == "__main__":
    main()
