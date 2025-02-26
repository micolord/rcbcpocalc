// new provider with different region
provider "alicloud" {
  alias   = "bridge"
  region  = "ap-northeast-1"
}

data "alicloud_zones" "bridge_zones" {
  provider          = alicloud.bridge
  available_resource_creation = "VSwitch"
}


resource "alicloud_vpc" "bridge_vpc" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  vpc_name   = "${var.env_name}-${var.project}-vpc"
  cidr_block = var.bridge_vpc_cidr
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
}

resource "alicloud_vswitch" "bridge_vswitch_a" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  vswitch_name = "${var.env_name}-${var.project}-vswitch-a"
  vpc_id       = alicloud_vpc.bridge_vpc[count.index].id
  cidr_block   = var.bridge_pub_a
  zone_id      = data.alicloud_zones.bridge_zones.zones.0.id
}


resource "alicloud_nat_gateway" "bridge_int_nat_gw1" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  vpc_id           = alicloud_vpc.bridge_vpc[count.index].id
  nat_gateway_name = "${var.env_name}-${var.project}-ingw1"
  payment_type     = "PayAsYouGo"
  vswitch_id       = alicloud_vswitch.bridge_vswitch_a[count.index].id
  nat_type         = "Enhanced"
}

resource "alicloud_eip_association" "bridge_int_nat_assoc1" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  allocation_id = alicloud_eip_address.bridge_eip_addr_snat1[count.index].id
  instance_type = "Nat"
  instance_id   = alicloud_nat_gateway.bridge_int_nat_gw1[count.index].id
}

resource "alicloud_eip_address" "bridge_eip_addr_snat1" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  address_name  = "${var.env_name}-${var.project}-eipaddr1"
  resource_group_id = alicloud_resource_manager_resource_group.rg.id 
}

resource "alicloud_snat_entry" "bridge_int_nat_snat1" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  snat_table_id     = alicloud_nat_gateway.bridge_int_nat_gw1[count.index].snat_table_ids
  source_vswitch_id = alicloud_vswitch.bridge_vswitch_a[count.index].id
  snat_ip           = alicloud_eip_address.bridge_eip_addr_snat1[count.index].ip_address
}

// SGRP
resource "alicloud_security_group" "bridge-sg" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  resource_group_id = alicloud_resource_manager_resource_group.rg.id
  name        = "${var.env_name}-${var.project}-bridge-sg"
  description = "${var.env_name}-${var.project} security group"
  vpc_id = alicloud_vpc.bridge_vpc[count.index].id
  lifecycle {
    create_before_destroy = true
  }
}

resource "alicloud_security_group_rule" "bridge-http" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-https" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-http-egress" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-https-egress" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-udp-dns-egress" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "udp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "bridge-tcp-dns-egress" {
  count = var.env_name != "dev" ? 1 : 0
  provider          = alicloud.bridge
  type              = "egress"
  ip_protocol       = "tcp"
  port_range        = "53/53"
  security_group_id = alicloud_security_group.bridge-sg[count.index].id
  cidr_ip           = "0.0.0.0/0"
}


resource "alicloud_instance" "bridge_ecs_instance_1" {
    count = var.env_name != "dev" ? 1 : 0
    provider             = alicloud.bridge
    resource_group_id    = alicloud_resource_manager_resource_group.rg.id 
    instance_name        = "${var.env_name}-${var.project}-bridge"
    image_id             = var.bridge_image_id
    instance_type        = "ecs.g7.large"
    security_groups      = [alicloud_security_group.bridge-sg[count.index].id]
    vswitch_id           = alicloud_vswitch.bridge_vswitch_a[count.index].id
    password             = "dynamic_random_password"
    system_disk_category = "cloud_essd"
    system_disk_size     = 100
    tags = {
        Name = "${var.env_name}-${var.project}-bridge"
    }
}

// define a public ip for bridge_ecs_instance_1
resource "alicloud_eip_address" "bridge_eip" {
    count = var.env_name != "dev" ? 1 : 0
    resource_group_id = alicloud_resource_manager_resource_group.rg.id
    provider = alicloud.bridge
    bandwidth = "100"
    internet_charge_type = "PayByTraffic"
}

// make sure bridge_ecs_instance_1 is public
resource "alicloud_eip_association" "bridge_eip_assoc" {
    count = var.env_name != "dev" ? 1 : 0
    provider    = alicloud.bridge
    instance_id = alicloud_instance.bridge_ecs_instance_1[count.index].id
    allocation_id = alicloud_eip_address.bridge_eip[count.index].id
}
