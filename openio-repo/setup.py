'''This is a web application to help create DEB & RPM package repositories'''

from setuptools import setup

setup(
    name='OpenIO Repository',
    version='0.1',
    long_description=__doc__,
    packages=['openio-repo'],
    include_package_data=False,
    zip_safe=False,
    install_requires=['Flask']
)
