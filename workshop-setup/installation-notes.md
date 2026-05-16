## 2026-03-12 Installation Notes
Largely based on the (slightly old) guide [kubernetes-on-raspberry-pi-with-k3s](https://carpie.net/articles/kubernetes-on-raspberry-pi-with-k3s)

### Imaging
Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to install RPi
OS Lite 64-bit (under 'Other' Operating Systems) on a microSD card (helpful to
have an adpater like
[this](https://www.amazon.co.uk/BENFEI-Adapter-Compatible-MacBook-Surface-Grau/dp/B0D9K82TNL).

#### OS Setup 
 - Set hostname (e.g. kmaster/kworker[01-03]), 
 - SSH access using password auth. 
 - Initial account credentials such as chef(password: raspberry). 
 - Enter Wifi details, TP-Link_AP_2A5A_01 (01267426). Don't enable RPi Connect.

Notes
- Writing a `.img.xz` file directly to SD card with `dd` did not give me a
  usable image. However, Graphical imager remembers settings so ClickOps is 
  not too bad
- Setting Wifi details here did not enable the Wifi interface on first boot

### First boot
- Connect RPi to monitor + keyboard, add SD card and USB, power on.
- Login with credentials set in
- If not automatically done enable wifi and connect:
```
sudo -i
nmcli radio wifi on
nmcli dev wifi connect TP-Link_AP_2A5A_01 --ask
ip -brief add
# Use your current IP address and configure it statically.
nmcli connection modify "TP-Link_AP_2A5A_01" ipv4.addresses "192.168.0.1[01-99]/24" ipv4.dns "192.168.0.254,8.8.8.8" ipv4.gateway "192.168.0.254" ipv4.method manual
systemctl restart NetworkManager
```
Note IP address - Can use this to connect from own device, monitor and keyboard
can be disconnected from Pi.

### Pre-install
On own device, edit `/etc/hosts` (optional):
```
xx.xx.xx.xx     kmaster
yy.yy.yy.yy		kworker1
# etc.
```
```
ssh chef@kmaster # for example
```
# Update cgroup settings for k3s and reboot:

# Setup USB, skip if USB already done. 

## Download vim packages and requirements
```
wget http://ftp.uk.debian.org/debian/pool/main/v/vim/vim-runtime_9.1.1230-2_all.deb \
http://ftp.uk.debian.org/debian/pool/main/v/vim/vim-common_9.1.1230-2_all.deb \
http://ftp.uk.debian.org/debian/pool/main/v/vim/vim_9.1.1230-2_arm64.deb \
http://ftp.uk.debian.org/debian/pool/main/g/gpm/libgpm2_1.20.7-11+b2_arm64.deb \
http://ftp.uk.debian.org/debian/pool/main/libs/libsodium/libsodium23_1.0.18-1+deb13u1_arm64.deb
```

## Get arm64 images for deployments
``` 
docker pull --platform linux/arm64 nginx:alpine
docker pull --platform linux/arm64 busybox
docker pull --platform linux/arm64 perl
docker pull --platform linux/arm64 prom/prometheus
docker pull --platform linux/arm64 grafana/grafana

echo 'FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    curl \
    bind-tools \
    stress-ng \
    iperf3 \
    fio \
    procps \
    htop

CMD ["sh"] ' > Dockerfile
docker buildx create --use
docker buildx inspect --bootstrap
```
Might need this if bootstrap fails.
```
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx inspect --bootstrap
```


# Attach blue USB, copy across setup script

Locally; enable scp access and 
```
scp ./setup-rpi-worker.sh chef@kmaster:~/ 
ssh chef@kmaster
sudo -i
chmod +x /home/chef/setup-rpi-worker.sh
```
*Workshop starts here* 
# Access RPi
```
ssh-keygen -t ed25519
ssh-copy-id  chef@kmaster # or whichever machine
```
# Install k3s for master or worker node

#### Master
```
ssh chef@kmaster
sudo -i
chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s
mkdir -p /var/lib/rancher/k3s/agent/images/
cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/
chmod +x /root/k3s/install.sh
INSTALL_K3S_SKIP_DOWNLOAD=true /root/k3s/install.sh
```
#### Worker

```
sudo -i
chmod +x /root/k3s/k3s-arm64
cp /root/k3s/k3s-arm64 /usr/local/bin/k3s
mkdir -p /var/lib/rancher/k3s/agent/images/
cp /root/k3s/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/
chmod +x /root/k3s/install.sh
# Token from master
export TOKEN=K103561143d0dd217a7b47530fcef849ca272676542a4b3267b58e69fd60e9619ce::server:2e8b2a9d3e971f8f2ab620ff3de960a8
# IP from master
export MASTER_IP=192.168.0.101
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN /root/k3s/install.sh
```

Label worker nodes
`sudo kubectl get no -o name | grep worker | xargs -I {} sudo kubectl label {} node-role.kubernetes.io/worker=worker`


### Notes/Todo
- Networking is probably the biggest sticking point, how best to set a static IP?
  (if this could be done in the image, then we would not need the initial
  connect to monitor)
- Suggest we do imaging and pre-install, participants can install k3s
- Note k3s suggest ssds as SD cards may struggle with IO load (see
  [Requirements](https://docs.k3s.io/installation/requirements#disks)) 

