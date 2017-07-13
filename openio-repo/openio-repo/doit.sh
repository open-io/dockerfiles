#! /bin/bash

# Importing the same key multiple time should be harmless
gpg --import /root/keyFile

FLASK_APP="openiorepo" OIOREPO_DESTDIR="/oiorepodestdir" flask run --host=0.0.0.0
