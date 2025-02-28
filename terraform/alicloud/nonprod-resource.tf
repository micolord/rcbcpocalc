data "alicloud_alb_zones" "default" {}

resource "alicloud_alb_load_balancer" "alb" {
  count = var.env_name != "prod" ? 1 : 0
  vpc_id                 = module.vpc.vpc_id
  resource_group_id     = alicloud_resource_manager_resource_group.rg.id 
  address_type           = "Internet"
  address_allocated_mode = "Fixed"
  load_balancer_name     = "${var.env_name}-${var.project}-alb"
  load_balancer_edition  = "StandardWithWaf"
  load_balancer_billing_config {
    pay_type = "PayAsYouGo"
  }
  tags = {
    name = "${var.env_name}-${var.project}-intra-alb"
  }
  zone_mappings {
    vswitch_id = module.vpc.vswitch_ids[1]
    zone_id    = data.alicloud_alb_zones.default.zones.1.id
  }
   zone_mappings {
    vswitch_id = module.vpc.vswitch_ids[2]
    zone_id    = data.alicloud_alb_zones.default.zones.0.id
  }
  modification_protection_config {
    status = "NonProtection"
  }
}


// listener port 80
resource "alicloud_alb_listener" "http_80" {
  count = var.env_name != "prod" ? 1 : 0
  load_balancer_id     = alicloud_alb_load_balancer.alb[count.index].id
  listener_protocol    = "HTTP"
  listener_port        = 80
  listener_description = "${var.env_name}-${var.project}-80-listener"
  x_forwarded_for_config {
    x_forwarded_for_proto_enabled = true
    x_forwarded_for_enabled = true
  }
  default_actions {
    type = "ForwardGroup"
    forward_group_config {
      server_group_tuples {
        server_group_id = alicloud_alb_server_group.server_group[count.index].id
      }
    }
  }
}


// listener port 443
resource "alicloud_alb_listener" "https_443" {
  count = var.env_name != "prod" ? 1 : 0
  load_balancer_id     = alicloud_alb_load_balancer.alb[count.index].id
  listener_protocol    = "HTTPS"
  listener_port        = 443
  listener_description = "${var.env_name}-${var.project}-443-listener"
  x_forwarded_for_config {
    x_forwarded_for_proto_enabled = true
    x_forwarded_for_enabled = true
  }
  default_actions {
    type = "ForwardGroup"
    forward_group_config {
      server_group_tuples {
       server_group_id = alicloud_alb_server_group.server_group[count.index].id
      }
    }
  }
  certificates {
    certificate_id = var.cert_id
  }
}

// Server Group
resource "alicloud_alb_server_group" "server_group" {
  count = var.env_name != "prod" ? 1 : 0
  protocol          = "HTTP"
  vpc_id            = module.vpc.vpc_id
  server_group_name = "${var.env_name}-${var.project}-server-grp"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
  health_check_config {
    health_check_connect_port = "80"
    health_check_enabled      = true
    health_check_codes        = ["http_2xx", "http_3xx"]
    health_check_interval     = "2"
    health_check_protocol     = "TCP"
    health_check_timeout      = 5
    healthy_threshold         = 3
    unhealthy_threshold       = 3
  }
  sticky_session_config {
    sticky_session_enabled = false
    cookie                 = "tf-example"
    sticky_session_type    = "Server"
  }
  servers {
    description = "${var.env_name}-${var.project}-server"
    port        = 80
    server_id   = alicloud_instance.server_1[count.index].id
    server_type = "Ecs"
    weight = 100
  }
}

// ECS
resource "alicloud_instance" "server_1" {
  count = var.env_name != "prod" ? 1 : 0
  resource_group_id    = alicloud_resource_manager_resource_group.rg.id 
  instance_name        = "${var.env_name}-${var.project}-server"
  image_id             = var.image_id
  instance_type        = "ecs.g7.large"
  security_groups      = [alicloud_security_group.nonprod-sg[count.index].id]
  vswitch_id           = module.vpc.vswitch_ids[1]
  password             = "dynamic_random_password"
  system_disk_category = "cloud_essd"
  system_disk_size     = 100
  tags = {
    Name = "${var.env_name}-${var.project}-server"
  }

}

// Security Group

resource "alicloud_security_group" "nonprod-sg" {
  count = var.env_name != "prod" ? 1 : 0
  resource_group_id = alicloud_resource_manager_resource_group.rg.id
  security_group_name  = "${var.env_name}-${var.project}-nonprod-sg"
  description = "${var.env_name}-${var.project} security group"
  vpc_id = module.vpc.vpc_id
}

resource "alicloud_security_group_rule" "nonprod-http" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "8080/8080"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = var.vpc_cidr
}

resource "alicloud_security_group_rule" "nonprod-http-default" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = var.vpc_cidr
}

resource "alicloud_security_group_rule" "nonprod-http-egress" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "nonprod-db-egress" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "3306/3306"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "nonprod-https-egress" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "nonprod-udp-dns-egress" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "nonprod-tcp-dns-egress" {
  count = var.env_name != "prod" ? 1 : 0
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.nonprod-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}
