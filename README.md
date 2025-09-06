# Kiwix-in-Proxmox

Hosting a kiwix web server in proxmox container.

## What is kiwix?

Kiwix is an open-source software that lets you access websites and educational content completely offline. It works by reading ZIM files, which are highly compressed versions of websites like Wikipedia, Wiktionary, and more. This makes Kiwix useful for places with limited or no internet access, such as schools, remote areas, or personal offline knowledge bases.

### 1. Hosting a kiwix server on port 8080 using proxmox container.

### 2. Prerequisites

- Proxmox VE 8.4.0
- Debian LXC container with internet access. 
- The container should be unprivileged.

### 3. Setup Steps

#### Changing the name server for the proxmox container

```
nano /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
```

#### Installing kiwix server in container

```
apt install kiwix
sudo apt install kiwix-tools
mkdir ~/kiwix 
cd ~/kiwix
wget https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic.zim
NOTE: You can add any .zim files form https://kiwix.org/en/applications/
```

#### Create a systemd service file

```
nano /etc/systemd/system/kiwix-serve.service
```

```
[Unit]
Description=Kiwix Offline Wiki Server
After=network.target
[Service]
ExecStart=/bin/sh -c '/usr/local/bin/kiwix-serve --port=8080 /root/kiwix/*.zim'
Restart=always
User=root
WorkingDirectory=/root/kiwix
[Install]
WantedBy=multi-user.target
```

#### Reload systemd & enable service

```
systemctl daemon-reload
systemctl enable kiwix-serve
systemctl start kiwix-serve
```

### 4. Accessing the website

```
http://<container-ip>:8080
```

Which in my case is 

```
http://192.168.1.126:8080
```
<img width="1919" height="983" alt="image" src="https://github.com/user-attachments/assets/1c810cbd-0a32-4b65-bd01-3d7c6028838a" />


