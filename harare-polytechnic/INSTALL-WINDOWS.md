# Harare Polytechnic DSpace 8 — Installation Guide

## Server details
| Item | Value |
|------|-------|
| ESXi host | hrepolyREP |
| Static IP | 192.168.26.3 |
| UI access | http://192.168.26.3:4000 |
| REST API | http://192.168.26.3:8080/server |

---

## Step 1 — Create a Linux VM on ESXi

Log into ESXi at `https://192.168.26.3/` as root, then:
1. Create a new VM → Ubuntu Server 22.04 LTS
2. Assign at least: **4 vCPU, 8 GB RAM, 100 GB disk**
3. Set the VM's network adapter to the same network as ESXi (192.168.26.x)
4. Boot the VM and install Ubuntu Server

---

## Step 2 — Install Docker on the Ubuntu VM

SSH into the VM, then:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker compose version
```

---

## Step 3 — Deploy DSpace

```bash
# Clone the repository
git clone <your-repo-url> /opt/harare-polytechnic-dspace
cd /opt/harare-polytechnic-dspace/harare-polytechnic

# Create the .env file
cp .env.example .env
# Edit if needed:
nano .env

# Start everything
docker compose up -d
```

First run downloads ~3 GB of images. Allow 5–10 minutes.

---

## Step 4 — Wait for DSpace to start

```bash
docker logs -f hpoly-dspace 2>&1 | grep -E "Started|ERROR"
```

Wait for: `Started ServerBootApplication`

---

## Step 5 — Create the administrator account

```bash
docker exec -it hpoly-dspace /dspace/bin/dspace create-administrator
```

Enter:
- Email:      `admin@harare-polytechnic.ac.zw`
- First name: `Admin`
- Last name:  `HPoly`
- Password:   `HPolyAdmin2025!`
- Language:   `en`

---

## Step 6 — Create faculty communities

```bash
bash setup-communities.sh
```

---

## Access the site

From any PC on the 192.168.26.x network:

**http://192.168.26.3:4000**

Log in at: http://192.168.26.3:4000/login

---

## LAN hostname access (optional)

To access via `http://hrepolyREP:4000` instead of the IP, add to the `hosts` file on each client PC:

- **Windows**: `C:\Windows\System32\drivers\etc\hosts`
- **Linux/Mac**: `/etc/hosts`

Add this line:
```
192.168.26.3  hrepolyREP
```

---

## Stop / Start

```bash
# Stop
docker compose down

# Start
docker compose up -d
```

Data is preserved in Docker volumes.
