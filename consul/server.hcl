datacenter = "devopsroad"
data_dir = "/opt/consul"
server = true
bootstrap_expect = 1
bind_addr = "CONSUL_LB_PRIVATE_IP"
client_addr = "0.0.0.0"

ui_config {
  enabled = true
}
