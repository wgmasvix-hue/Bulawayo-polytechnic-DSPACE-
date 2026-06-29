# Harare Polytechnic DSpace 8 — Windows Installation Guide

## Prerequisites

### 1. Enable WSL2
Open PowerShell as Administrator and run:
```powershell
wsl --install
```
Restart the PC when prompted.

### 2. Install Docker Desktop
Download from: https://www.docker.com/products/docker-desktop/

During installation:
- Select "Use WSL 2 instead of Hyper-V"
- After install, open Docker Desktop and wait for it to start (whale icon in taskbar turns steady)

---

## Setup

### 3. Create the project folder
Open PowerShell and run:
```powershell
mkdir C:\dspace\harare-polytechnic
```

### 4. Copy files
Copy the contents of this `harare-polytechnic/` folder into `C:\dspace\harare-polytechnic\`.

Your folder should look like:
```
C:\dspace\harare-polytechnic\
  docker-compose.yml
  config.yml
  .env
  dspace-config\
    local.cfg
  setup-communities.sh
```

### 5. Create the .env file
Copy `.env.example` to `.env`:
```powershell
Copy-Item C:\dspace\harare-polytechnic\.env.example C:\dspace\harare-polytechnic\.env
```
Open `.env` in Notepad and confirm the password.

### 6. Start DSpace
```powershell
cd C:\dspace\harare-polytechnic
docker compose up -d
```

First run downloads ~3 GB of images. Wait 3–5 minutes.

### 7. Check it's running
```powershell
docker ps
```
All four containers should show `healthy` or `Up`:
- `hpoly-dspace`
- `hpoly-dspacedb`
- `hpoly-dspacesolr`
- `hpoly-angular`

Watch DSpace start:
```powershell
docker logs -f hpoly-dspace
```
Wait for: `Started ServerBootApplication`

---

## Create the Administrator Account

```powershell
docker exec -it hpoly-dspace /dspace/bin/dspace create-administrator
```

Enter:
- Email:      `admin@harare-polytechnic.ac.zw`
- First name: `Admin`
- Last name:  `HPoly`
- Password:   `HPolyAdmin2025!`
- Language:   `en`

---

## Access the Site

| URL | Purpose |
|-----|---------|
| http://localhost:4000 | Main website (Angular UI) |
| http://localhost:8080/server | REST API |

Log in at: http://localhost:4000/login

---

## Create Faculty Communities

Run from PowerShell (requires Git Bash or WSL):
```bash
bash setup-communities.sh
```

Or from WSL terminal:
```bash
cd /mnt/c/dspace/harare-polytechnic
bash setup-communities.sh
```

---

## Stop / Start

```powershell
# Stop
docker compose down

# Start again
docker compose up -d
```

Data is preserved in Docker volumes — stopping containers does not delete anything.

---

## Troubleshooting

**Site not loading after 5 minutes:**
```powershell
docker logs hpoly-dspace --tail 30
docker logs hpoly-angular --tail 30
```

**Reset everything (WARNING — deletes all data):**
```powershell
docker compose down -v
docker compose up -d
```
