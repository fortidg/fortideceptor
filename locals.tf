locals {
  students = {
    "student1" = {
      name    = "student1"
      trust_range = "192.168.1.0/24"
      tools_range = "10.0.1.0/24"
      p2ip = "192.168.1.10"
      p3ip = "10.0.1.10"
      kalip = "192.168.1.11"
      decp1 = "10.0.1.13"
      decp2 = "192.168.1.13"
    }
    "student2" = {
      name    = "student2"
      trust_range = "192.168.2.0/24"
      tools_range = "10.0.2.0/24"
      p2ip = "192.168.2.10"
      p3ip = "10.0.2.10"
      kalip = "192.168.2.11"
      decp1 = "10.0.2.13"
      decp2 = "192.168.2.13"
    }
          
  }
}