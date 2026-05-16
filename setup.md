# SETUP – Project 05 Consul Service Discovery with Nginx

## 1. Local variables

```bash
export AWS_REGION="eu-central-1"
export KEY_NAME="devopsroad-key"
export PROJECT_NAME="project-05-consul"
```

## 2. Get Ubuntu 22.04 AMI

```bash
export AMI_ID=$(aws ssm get-parameters \
  --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id \
  --region $AWS_REGION \
  --query "Parameters[0].Value" \
  --output text)

echo $AMI_ID
```

## 3. Get default VPC and subnet

```bash
export VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=true" \
  --region $AWS_REGION \
  --query "Vpcs[0].VpcId" \
  --output text)

export SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --region $AWS_REGION \
  --query "Subnets[0].SubnetId" \
  --output text)

echo $VPC_ID
echo $SUBNET_ID
```

## 4. Create Security Group

```bash
export SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_NAME}-sg" \
  --description "Security group for Consul Nginx service discovery lab" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query "GroupId" \
  --output text)

echo $SG_ID
```

## 5. Configure Security Group rules

Get current public IP:

```bash
export MY_IP=$(curl -s https://checkip.amazonaws.com)/32
echo $MY_IP
```

Allow SSH from local machine:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr $MY_IP \
  --region $AWS_REGION
```

Allow SSH between project instances:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --source-group $SG_ID \
  --region $AWS_REGION
```

Allow public HTTP traffic:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION
```

Allow Consul UI from local machine:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8500 \
  --cidr $MY_IP \
  --region $AWS_REGION
```

Allow Consul internal communication:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8300 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8301 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol udp \
  --port 8301 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8302 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol udp \
  --port 8302 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8600 \
  --source-group $SG_ID \
  --region $AWS_REGION

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol udp \
  --port 8600 \
  --source-group $SG_ID \
  --region $AWS_REGION
```

## 6. Create EC2 instances

### consul-lb

```bash
export CONSUL_LB_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=consul-lb},{Key=Project,Value=$PROJECT_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" \
  --output text)

echo $CONSUL_LB_INSTANCE_ID
```

### web1

```bash
export WEB1_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=web1},{Key=Project,Value=$PROJECT_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" \
  --output text)

echo $WEB1_INSTANCE_ID
```

### web2

```bash
export WEB2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=web2},{Key=Project,Value=$PROJECT_NAME}]" \
  --region $AWS_REGION \
  --query "Instances[0].InstanceId" \
  --output text)

echo $WEB2_INSTANCE_ID
```

Wait for the instances:

```bash
aws ec2 wait instance-running \
  --instance-ids $CONSUL_LB_INSTANCE_ID $WEB1_INSTANCE_ID $WEB2_INSTANCE_ID \
  --region $AWS_REGION
```

## 7. Save IP addresses

```bash
export CONSUL_LB_PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $CONSUL_LB_INSTANCE_ID \
  --region $AWS_REGION \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

export CONSUL_LB_PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $CONSUL_LB_INSTANCE_ID \
  --region $AWS_REGION \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

export WEB1_PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $WEB1_INSTANCE_ID \
  --region $AWS_REGION \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

export WEB2_PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $WEB2_INSTANCE_ID \
  --region $AWS_REGION \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)

echo "consul-lb public:  $CONSUL_LB_PUBLIC_IP"
echo "consul-lb private: $CONSUL_LB_PRIVATE_IP"
echo "web1 private:      $WEB1_PRIVATE_IP"
echo "web2 private:      $WEB2_PRIVATE_IP"
```

## 8. Copy SSH key to consul-lb

```bash
scp -i ../devopsroad-key.pem ../devopsroad-key.pem ubuntu@$CONSUL_LB_PUBLIC_IP:/home/ubuntu/devopsroad-key.pem
```

Connect to `consul-lb`:

```bash
ssh -i ../devopsroad-key.pem ubuntu@$CONSUL_LB_PUBLIC_IP
```

Set key permissions on `consul-lb`:

```bash
chmod 400 ~/devopsroad-key.pem
```

## 9. Install Consul and Nginx

Run on all three instances: `consul-lb`, `web1`, and `web2`.

```bash
sudo apt update
sudo apt install unzip curl nginx -y

export CONSUL_VERSION="1.18.0"

curl -LO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

unzip consul_${CONSUL_VERSION}_linux_amd64.zip

sudo mv consul /usr/local/bin/

consul version
```

## 10. Configure Consul server on consul-lb

On `consul-lb`:

```bash
sudo mkdir -p /etc/consul.d /opt/consul
sudo nano /etc/consul.d/server.hcl
```

Content:

```hcl
datacenter = "devopsroad"
data_dir = "/opt/consul"
server = true
bootstrap_expect = 1
bind_addr = "CONSUL_LB_PRIVATE_IP"
client_addr = "0.0.0.0"

ui_config {
  enabled = true
}
```

Start Consul server:

```bash
consul agent -config-dir=/etc/consul.d
```

Keep this terminal open.

## 11. Configure web1

Connect from `consul-lb` to `web1`:

```bash
ssh -i ~/devopsroad-key.pem ubuntu@WEB1_PRIVATE_IP
```

Configure backend page:

```bash
echo "<h1>Backend 1 from Consul Discovery</h1>" | sudo tee /var/www/html/index.html
sudo systemctl restart nginx
curl http://localhost
```

Create Consul agent config:

```bash
sudo mkdir -p /etc/consul.d /opt/consul
sudo nano /etc/consul.d/client.hcl
```

Content:

```hcl
datacenter = "devopsroad"
data_dir = "/opt/consul"
server = false
bind_addr = "WEB1_PRIVATE_IP"
client_addr = "0.0.0.0"
retry_join = ["CONSUL_LB_PRIVATE_IP"]
```

Register service:

```bash
sudo nano /etc/consul.d/web.json
```

Content:

```json
{
  "service": {
    "name": "web",
    "tags": ["nginx", "web1"],
    "port": 80,
    "check": {
      "http": "http://localhost",
      "interval": "10s"
    }
  }
}
```

Start Consul agent:

```bash
consul agent -config-dir=/etc/consul.d
```

Keep this terminal open.

## 12. Configure web2

Connect from `consul-lb` to `web2`:

```bash
ssh -i ~/devopsroad-key.pem ubuntu@WEB2_PRIVATE_IP
```

Configure backend page:

```bash
echo "<h1>Backend 2 from Consul Discovery</h1>" | sudo tee /var/www/html/index.html
sudo systemctl restart nginx
curl http://localhost
```

Create Consul agent config:

```bash
sudo mkdir -p /etc/consul.d /opt/consul
sudo nano /etc/consul.d/client.hcl
```

Content:

```hcl
datacenter = "devopsroad"
data_dir = "/opt/consul"
server = false
bind_addr = "WEB2_PRIVATE_IP"
client_addr = "0.0.0.0"
retry_join = ["CONSUL_LB_PRIVATE_IP"]
```

Register service:

```bash
sudo nano /etc/consul.d/web.json
```

Content:

```json
{
  "service": {
    "name": "web",
    "tags": ["nginx", "web2"],
    "port": 80,
    "check": {
      "http": "http://localhost",
      "interval": "10s"
    }
  }
}
```

Start Consul agent:

```bash
consul agent -config-dir=/etc/consul.d
```

Keep this terminal open.

## 13. Verify Consul cluster

On `consul-lb`:

```bash
consul members
```

Expected result:

```text
consul-lb    alive    server
web1         alive    client
web2         alive    client
```

Check service health:

```bash
curl -s http://127.0.0.1:8500/v1/health/checks/web | grep -E "Node|Status"
```

Expected result:

```text
"Node": "web1"
"Status": "passing"
"Node": "web2"
"Status": "passing"
```

## 14. Install Consul Template on consul-lb

On `consul-lb`:

```bash
export CONSUL_TEMPLATE_VERSION="0.35.0"

curl -LO https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip

sudo mv consul-template /usr/local/bin/

consul-template -version
```

## 15. Create Nginx template

On `consul-lb`:

```bash
sudo nano /etc/nginx/nginx.ctmpl
```

Content:

```nginx
upstream web_backend {
{{ range service "web" }}
    server {{ .Address }}:{{ .Port }};
{{ end }}
}

server {
    listen 80;

    location / {
        proxy_pass http://web_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Generate the Nginx config once:

```bash
sudo consul-template \
  -consul-addr="127.0.0.1:8500" \
  -template="/etc/nginx/nginx.ctmpl:/etc/nginx/sites-available/consul-lb" \
  -once
```

Enable the generated config:

```bash
sudo ln -sf /etc/nginx/sites-available/consul-lb /etc/nginx/sites-enabled/consul-lb
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

Run Consul Template continuously:

```bash
sudo consul-template \
  -consul-addr="127.0.0.1:8500" \
  -template="/etc/nginx/nginx.ctmpl:/etc/nginx/sites-available/consul-lb:systemctl reload nginx"
```

Keep this terminal open.

## 16. Test load balancing

On `consul-lb`:

```bash
curl http://localhost
curl http://localhost
curl http://localhost
curl http://localhost
```

Expected result:

```text
Backend 1 from Consul Discovery
Backend 2 from Consul Discovery
```

## 17. Test service discovery

Stop Nginx on `web1`:

```bash
sudo systemctl stop nginx
```

Wait 10–20 seconds.

On `consul-lb`:

```bash
curl -s http://127.0.0.1:8500/v1/health/checks/web | grep -E "Node|Status"
```

Expected result:

```text
"Node": "web1"
"Status": "critical"
"Node": "web2"
"Status": "passing"
```

Check the generated Nginx upstream:

```bash
sudo cat /etc/nginx/sites-available/consul-lb
```

Only `web2` should remain in the upstream.

Test the load balancer:

```bash
curl http://localhost
curl http://localhost
curl http://localhost
```

Only Backend 2 should respond.

Start Nginx again on `web1`:

```bash
sudo systemctl start nginx
```

Wait 10–20 seconds.

On `consul-lb`:

```bash
curl -s http://127.0.0.1:8500/v1/health/checks/web | grep -E "Node|Status"
```

Both backends should return to `passing`.
