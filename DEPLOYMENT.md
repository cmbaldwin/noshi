# Deployment Guide - Noshi on Hetzner with Kamal

This guide will help you deploy the Noshi application to a Hetzner server using Kamal.

## Prerequisites

1. **Hetzner Server**: A server running Ubuntu 22.04 or later
2. **Domain Name**: A domain pointing to your Hetzner server IP
3. **Docker Registry**: Docker Hub account or GitHub Container Registry access
4. **SSH Access**: SSH key-based authentication to your server

## Server Setup

### 1. Initial Server Configuration

SSH into your Hetzner server and run:

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (optional, for non-root Docker access)
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker
```

### 2. Firewall Configuration

```bash
# Allow SSH, HTTP, and HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Local Setup

### 1. Update Configuration Files

Edit `config/deploy.yml`:

```yaml
servers:
  web:
    - YOUR_HETZNER_SERVER_IP  # Replace with actual IP

proxy:
  host: noshi.yourdomain.com  # Replace with your domain

accessories:
  redis:
    host: YOUR_HETZNER_SERVER_IP  # Replace with actual IP
```

### 2. Set Up Environment Variables

Create or update your environment variables:

```bash
# Docker Registry Password (Docker Hub token or GitHub PAT)
export KAMAL_REGISTRY_PASSWORD="your_registry_token"

# Redis URL (will be set after first deploy)
export REDIS_URL="redis://YOUR_HETZNER_SERVER_IP:6379/0"
```

### 3. Ensure Rails Master Key Exists

Make sure `config/master.key` exists. If not, generate credentials:

```bash
EDITOR=vim rails credentials:edit
```

## Deployment Steps

### 1. Initial Setup on Server

This sets up Docker and other prerequisites on the server:

```bash
bin/kamal setup
```

This command will:
- Install Docker on the server
- Set up the Redis accessory
- Build and push your Docker image
- Deploy the application
- Set up SSL certificates via Let's Encrypt

### 2. Subsequent Deployments

For regular deployments after changes:

```bash
bin/kamal deploy
```

### 3. Deploy Specific Commands

```bash
# Deploy only the app (skip accessories)
bin/kamal app deploy

# Restart the app without rebuilding
bin/kamal app restart

# Roll back to previous version
bin/kamal app rollback

# View logs
bin/kamal app logs

# SSH into the server
bin/kamal app exec -i --reuse bash

# Check app status
bin/kamal app details
```

## Useful Kamal Commands

### Logs and Monitoring

```bash
# Tail application logs
bin/kamal app logs -f

# View Redis logs
bin/kamal accessory logs redis

# Check running containers
bin/kamal app containers
```

### Maintenance

```bash
# Stop the application
bin/kamal app stop

# Start the application
bin/kamal app start

# Remove old images (cleanup)
bin/kamal prune all

# Update environment variables
bin/kamal env push
```

### Redis Management

```bash
# Restart Redis
bin/kamal accessory restart redis

# Stop Redis
bin/kamal accessory stop redis

# Start Redis
bin/kamal accessory start redis

# SSH into Redis container
bin/kamal accessory exec redis redis-cli
```

## Troubleshooting

### SSL Certificate Issues

If Let's Encrypt fails:

```bash
# Check proxy logs
bin/kamal proxy logs

# Ensure your domain DNS is correctly pointing to the server
# Let's Encrypt requires the domain to resolve to the server IP

# Restart the proxy
bin/kamal proxy restart
```

### Application Won't Start

```bash
# Check app logs
bin/kamal app logs --tail 100

# Verify environment variables
bin/kamal app exec 'env | grep RAILS'

# Check if Redis is accessible
bin/kamal accessory exec redis redis-cli ping
```

### Docker Registry Issues

```bash
# Verify registry credentials
echo $KAMAL_REGISTRY_PASSWORD

# Try manual Docker login
docker login -u cmbaldwin

# Check if image exists
docker images | grep noshi
```

### SSH Connection Issues

```bash
# Test SSH connection
ssh YOUR_HETZNER_SERVER_IP

# Verify SSH key is added
ssh-add -l

# Check Kamal SSH configuration
bin/kamal config
```

## Configuration Files Reference

### config/deploy.yml

Main Kamal configuration file defining:
- Service name and Docker image
- Server hosts
- SSL/proxy settings
- Environment variables
- Redis accessory configuration

### .kamal/secrets

Environment-specific secrets (not committed to git):
- `KAMAL_REGISTRY_PASSWORD`: Docker registry token
- `RAILS_MASTER_KEY`: Rails credentials encryption key
- `REDIS_URL`: Redis connection URL

### Dockerfile

Multi-stage Docker build configuration:
- Base Ruby 3.3.6 image
- Gem installation and precompilation
- Asset precompilation
- Thruster HTTP/2 proxy setup

## Post-Deployment Checklist

- [ ] Verify app is accessible at your domain
- [ ] Check SSL certificate is valid (https)
- [ ] Test Redis connectivity
- [ ] Verify logs are being written
- [ ] Test application functionality
- [ ] Set up monitoring (optional)
- [ ] Set up backups (if needed)

## Upgrading

To upgrade Ruby, Rails, or gems:

1. Update locally and test
2. Commit changes
3. Run `bin/kamal deploy`

Kamal will:
- Build a new image with updates
- Deploy with zero-downtime rolling restart
- Keep previous version for quick rollback if needed

## Support

For Kamal documentation: https://kamal-deploy.org/
For Rails 8 documentation: https://guides.rubyonrails.org/
