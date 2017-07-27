#! /bin/bash -xe

# Ensure we can run arm binaries automagically through qemu via binfmt_misc
update-binfmts --display | grep -q 'qemu-arm (enabled)'
if [ $? -ne 0 ]; then
    sudo update-binfmts --enable qemu-arm
fi

pbuilder create
