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
  default = "192.168.128.0/24"
}

# user data for bootstrap fgt configuration
variable "user_data" {
  type    = string
  default = "config.txt"
}

variable "deceptor_image" {
  type = string
  default = "projects/cselab-demo/global/images/fortideceptor"
}

variable "deceptor_machine" {
  type = string
  default = "e2-highcpu-16"
}