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

## AWS Infrastructure

The project uses three Ubuntu EC2 instances in the same VPC and Security Group.

| Instance | Role |
|---|---|
| consul-lb | Consul server, Nginx load balancer, Consul Template |
| web1 | Nginx backend and Consul agent |
| web2 | Nginx backend and Consul agent |

Inbound access:
- SSH allowed only from my public IP
- HTTP allowed publicly on port 80
- Consul UI allowed only from my public IP on port 8500
- Consul internal ports allowed only inside the Security Group
