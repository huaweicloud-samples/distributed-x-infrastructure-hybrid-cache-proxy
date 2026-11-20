# ============================================================================
# 华为云对象存储缓存代理 Terraform 配置
# ============================================================================
# 基于混合缓存代理参考架构适配
# 架构：CCE + SFS + OBS
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.96"
    }
  }
}

provider "huaweicloud" {
  region     = var.region
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}

# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称"
  type        = string
  default     = "hybrid-cache-proxy"
}

# ============================================================================
# Layer 1: VPC 网络
# ============================================================================

resource "huaweicloud_vpc" "main" {
  name                  = "${var.project_name}-vpc"
  cidr                  = "10.5.0.0/16"
  enterprise_project_id = "0"
}

resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "10.5.1.0/24"
  gateway_ip = "10.5.1.1"
}

# ============================================================================
# Layer 2: 安全组
# ============================================================================

resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for hybrid cache proxy"
}

resource "huaweicloud_networking_secgroup_rule" "ingress_proxy" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 3129
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "ingress_admin" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 8080
  port_range_max   = 9090
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

# ============================================================================
# Layer 3: OBS 对象存储
# ============================================================================

resource "huaweicloud_obs_bucket" "cache" {
  bucket     = "${var.project_name}-cache"
  acl        = "private"
  storage_class = "STANDARD"
}

# ============================================================================
# Layer 4: SFS Turbo (替代 NFS)
# ============================================================================

resource "huaweicloud_sfs_turbo" "cache" {
  name               = "${var.project_name}-turbo-20260821"
  size              = 500
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.main.id
  security_group_id = huaweicloud_networking_secgroup.main.id
  availability_zone = "cn-north-4a"
}

# ============================================================================
# Layer 5: EIP (公网访问)
# ============================================================================

resource "huaweicloud_vpc_eip" "proxy" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name       = "${var.project_name}-eip"
    size       = 10
    share_type = "PER"
  }
}

# ============================================================================
# 输出
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = huaweicloud_vpc.main.id
}

output "obs_bucket" {
  description = "OBS Bucket"
  value       = huaweicloud_obs_bucket.cache.bucket
}

output "sfs_id" {
  description = "SFS File System ID"
  value       = huaweicloud_sfs_turbo.cache.id
}

output "eip" {
  description = "EIP Address"
  value       = huaweicloud_vpc_eip.proxy.address
}

# ============================================================================
# 说明
# ============================================================================
#
# CCE 集群需要通过控制台创建，或使用 huaweicloud_cce_cluster 资源
# Docker 镜像需要提前构建并推送到 SWR
#
# ============================================================================
