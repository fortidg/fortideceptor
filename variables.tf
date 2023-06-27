# GCP region string
variable "region" {
  type    = string
  default = "us-central1" #Default Region
}
# GCP zone
variable "zone" {
  type    = string
  default = "us-central1-c" #Default Zone
}
# GCP project name
variable "project" {
  type    = string
  default = "cselab-demo"
}

# GCP oauth access token
/* variable "token" {
  type    = string
} */

# FortiGate Image name
# 7.2.3 payg is projects/fortigcp-project-001/global/images/fortinet-fgtondemand-725-20230613-001-w-license
# 7.2.3 byol is projects/fortigcp-project-001/global/images/fortinet-fgt-725-20230613-001-w-license
variable "image" {
  type    = string
  default = "projects/fortigcp-project-001/global/images/fortinet-fgtondemand-725-20230613-001-w-license"
}

variable "kali-image" {
  type    = string
  default = "projects/techlatest-public/global/images/kali-linux-in-browser-v01"
}

variable "win-image" {
  type    = string
  default = "projects/windows-cloud/global/images/windows-server-2022-dc-core-v20230615"
}

# GCP instance machine type for windows
variable "win-machine" {
  type    = string
  default = "e2-medium"
}

# GCP instance machine type standard
variable "machine" {
  type    = string
  default = "n1-standard-4"
}

# Public Subnet CIDR
variable "public_subnet" {
  type    = string
  default = "192.168.128.0/25"
}
# Private Subnet CIDR
variable "protected_subnet" {
  type    = string
  default = "192.168.129.0/25"
}

# Tools Subnet CIDR
variable "tools_subnet" {
  type    = string
  default = "192.168.130.0/25"
}

# FortiGate Trust IP
variable "fgt_port2_ip" {
  type    = string
  default = "192.168.129.2"
}

# FortiGate Tools IP
variable "fgt_port3_ip" {
  type    = string
  default = "192.168.130.2"
}

# Kali IP
variable "kali_ip" {
  type    = string
  default = "192.168.129.3"
}

# Kali IP
variable "win_ip" {
  type    = string
  default = "192.168.129.4"
}

# user data for bootstrap fgt configuration
variable "user_data" {
  type    = string
  default = "config.txt"
}

# user data for bootstrap fgt license file
variable "license_file" {
  type    = string
  default = "license.lic" #FGT BYOL license
}
