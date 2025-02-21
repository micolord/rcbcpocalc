// PROJECT NETWORK VARIABLES
variable "env_name" {
    description = "Environment Name"
}

variable "project" {
    description = "PROJECT NAME"
}

variable "region" {
    description = "REGION"
}

variable "vpc_cidr" {
    description = "VPC CIDR"
}

variable "priv_a" {
    description = "PRIVATE SWITCH"
}

variable "priv_b" {
    description = "PRIVATE SWITCH"
}

variable "priv_c" {
    description = "PRIVATE SWITCH"
}

variable "pub_a" {
    description = "PUBLIC SWITCH"
}

variable "az_a" {
    description = "AVAILABILITY ZONE"
}

variable "az_b" {
    description = "AVAILABILITY ZONE"
}

variable "cert_id" {
    description = "CERTIFICATE ID"
}

// PROJECT INSTANCE VARIABLES
variable "image_id" {
    description = "ECS IMAGE ID"
}

variable "gl_fe_image_id" {
    description = "ECS IMAGE ID"
}

variable "gl_be_image_id" {
    description = "ECS IMAGE ID"
}

variable "bo_fe_image_id" {
    description = "ECS IMAGE ID"
}

variable "bo_be_image_id" {
    description = "ECS IMAGE ID"
}

variable "jp_image_id" {
    description = "ECS IMAGE ID"
}


variable "gl_fe_domain" {
    description = "GL FE DOMAIN"
}

variable "gl_be_domain" {
    description = "GL BE DOMAIN"
}

variable "bo_fe_domain" {
    description = "BO FE DOMAIN"
}

variable "bo_be_domain" {
    description = "BO BE DOMAIN"
}

variable "jobproc_domain" {
    description = "JP DOMAIN"
}


// PROJECT DB VARIABLES
variable "db_instance_type" {
    description = "DATABASE INSTANCE TYPE"
}
variable "db_instance_storage" {
    description = "DATABASE INSTANCE STORAGE"
}

// PROJECT BRIDGE INSTANCE VARIABLES
variable "bridge_image_id" {
    description = "BRIDGE INSTANCE STORAGE"
}
variable "db_category" {
    description = "DB CATEGORY"
}
variable "db_engine_version" {
    description = "DB VERSION"
}

variable "bridge_vpc_cidr" {
    description = "VPC CIDR"
}

variable "bridge_pub_a" {
    description = "PUBLIC SWITCH"
}

variable "bridge_az_a" {
    description = "AVAILABILITY ZONE"
}

