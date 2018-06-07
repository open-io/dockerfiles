Raspberry Pi 3B Ubuntu Xenial ARM64 Image builder
---

This builder builds an image of Ubuntu Xenial arm64 ready to be set on Raspberry Pi

### How to build

Clone the current repository and cd into it, then:

```sh
docker build -t rpi-ubuntu-build .
mkdir -p result
docker run --rm -ti -v $(pwd)/result:/root/.mnt/img --privileged rpi-ubuntu-build
```

The image will be available in `./result/ubuntu_xenial_arm64_rpi.img`. You can then burn it onto the Raspberry Pi:

```sh
sudo dd if=$(pwd)/result/ubuntu_xenial_arm64_rpi.img of=/dev/mmcblk0 status=progress bs=4M
```
