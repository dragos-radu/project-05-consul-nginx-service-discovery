# Project 05 – Consul Service Discovery with Nginx

## Goal

Deploy a dynamic load balancing setup using Consul, Consul Template and Nginx.

Backend servers register themselves in Consul, and Nginx updates its upstream configuration automatically based on available healthy services.

## Architecture

```
Client
  |
Nginx Load Balancer
  |
Consul Template
  |
Consul Server
  |
Web1 + Web2 registered as services
```

## Jira

Epic: **DEVOPS-20** – Configure Service Discovery with Consul and Nginx

### Tasks

- **DEVOPS-21** – Create AWS instances
- **DEVOPS-22** – Install Consul server
- **DEVOPS-23** – Register backend services
- **DEVOPS-24** – Configure Nginx dynamic upstream
- **DEVOPS-25** – Test backend add/remove

## Tech Stack

- AWS EC2
- Ubuntu 22.04
- Nginx
- Consul
- Consul Template

## Status

In progress
