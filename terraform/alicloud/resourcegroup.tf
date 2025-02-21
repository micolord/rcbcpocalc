resource "alicloud_resource_manager_resource_group" "rg" {
  resource_group_name ="${var.env_name}-${var.project}-rg"
  display_name        = "Resource Group of ${var.env_name}-${var.project}"
}