locals {
  students = {
    "student1" = {
      name    = "student1"
      disk = "fgt-log-disk-student1"
      trust_range = "192.168.1.0/24"
      tools_range = "10.0.1.0/24"
      p1ip = "192.168.128.11"
      p2ip = "192.168.1.10"
      p3ip = "10.0.1.10"
      license_file = "student1.lic"
      kalip = "192.168.1.11"
      winip = "192.168.1.12"
    }
    "student2" = {
      name    = "student2"
      disk = "fgt-log-disk-student2"
      trust_range = "192.168.2.0/24"
      tools_range = "10.0.2.0/24"
      p1ip = "192.168.128.12"
      p2ip = "192.168.2.10"
      p3ip = "10.0.2.10"
      license_file = "student2.lic"
      kalip = "192.168.2.11"
      winip = "192.168.2.12"
    }
          
  }
}