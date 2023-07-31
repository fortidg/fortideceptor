locals {
  students = {
    "student1" = {
      name    = "student1"
      trust_range = "10.10.1.0/24"
      tools_range = "10.0.1.0/24"
      p2ip = "10.10.1.10"
      p3ip = "10.0.1.10"
      kalip = "10.10.1.201"
      decp1 = "10.0.1.100"
      decp2 = "10.10.1.11"
    }
    "student2" = {
      name    = "student2"
      trust_range = "10.10.2.0/24"
      tools_range = "10.0.2.0/24"
      p2ip = "10.10.2.10"
      p3ip = "10.0.2.10"
      kalip = "10.10.2.201"
      decp1 = "10.0.2.100"
      decp2 = "10.10.2.11"
    }
          
  }
}