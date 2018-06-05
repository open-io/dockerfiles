Raspberry Pi 3B Ubuntu Xenial ARM64 Image builder
---

This builder builds an image with OpenIO SDS preinstalled, ready to be set on Raspberry Pi

### How to build

Clone the current repository and cd into it, then:

```sh
docker build -t rpi-openio-build .
mkdir -p result
docker run --rm -ti -v $(pwd)/result:/root/.mnt/img --privileged rpi-openio-build
```

The image will be available in `./result/openio.img`. You can then burn it onto the Raspberry Pi:

```sh
sudo dd if=$(pwd)/result/openio.img of=/dev/mmcblk0 status=progress bs=4M
```
