### GCP terraform
terraform {
  required_version = ">=0.12.0"
  required_providers {
    google      = ">=2.11.0"
    google-beta = ">=2.13"
  }
}
provider "google" {
  project      = var.project
  region       = var.region
  zone         = var.zone
  /* access_token = var.token */
}
provider "google-beta" {
  project      = var.project
  region       = var.region
  zone         = var.zone
  /* access_token = var.token */
}

# Randomize string to avoid duplication
resource "random_string" "random_name_post" {
  length           = 3
  special          = true
  override_special = ""
  min_lower        = 3
}

# Create log disk

resource "google_compute_disk" "logdisk" {
  for_each = local.students
  name = "fgt-log-disk-${each.value.name}"
  size = 30
  type = "pd-standard"
  zone = var.zone
}

resource "google_compute_disk" "deceptordisk" {
  for_each = local.students
  name = "deceptor-disk-${each.value.name}"
  size = 200
  type = "pd-standard"
  zone = var.zone
}

### VPC ###
resource "google_compute_network" "untrust" {
  name                    = "untrust-deceptor"
  auto_create_subnetworks = false
}

resource "google_compute_network" "trust" {
  name                    = "trust-deceptor"
  auto_create_subnetworks = false
}

resource "google_compute_network" "tools" {
  name                    = "tools-deceptor"
  auto_create_subnetworks = false
}

### Public Subnet ###
resource "google_compute_subnetwork" "untrust" {
  name                     = "untrust-subnet-deceptor"
  region                   = var.region
  network                  = google_compute_network.untrust.name
  ip_cidr_range            = var.public_subnet
  private_ip_google_access = true
}
### Private Subnet ###
resource "google_compute_subnetwork" "trust" {
  for_each = local.students
  name          = "trust-subnet-${each.value.name}"
  region        = var.region
  network       = google_compute_network.trust.name
  ip_cidr_range = "${each.value.trust_range}"
}

### Tools Subnet ###

resource "google_compute_subnetwork" "tools" {
  for_each = local.students
  name          = "tools-subnet-${each.value.name}"
  region        = var.region
  network       = google_compute_network.tools.name
  ip_cidr_range = "${each.value.tools_range}"
}

resource "google_compute_route" "default-trust" {
  for_each = local.students
  name        = "default-trust-${each.value.name}"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.trust.name
  next_hop_ip = "${each.value.p2ip}"
  priority    = 100
  depends_on  = [google_compute_subnetwork.trust]
  tags = ["${each.value.name}"]
}

resource "google_compute_route" "default-tools" {
  for_each = local.students
  name        = "default-tools-${each.value.name}"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.tools.name
  next_hop_ip = "${each.value.p3ip}"
  priority    = 100
  depends_on  = [google_compute_subnetwork.tools]
  tags = ["${each.value.name}"]

}

# Firewall Rule External
resource "google_compute_firewall" "allow-all-fgt" {
  name    = "allow-fgt-deceptor"
  network = google_compute_network.untrust.name

  allow {
    protocol = "all"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-fgt"]
}

# Firewall Rule Internal
resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal-deceptor"
  network = google_compute_network.trust.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-internal"]
}

# Firewall Rule Tools
resource "google_compute_firewall" "allow-tools" {
  name    = "allow-tools-deceptor"
  network = google_compute_network.tools.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-internal"]
}

# Create Static Public IP
resource "google_compute_address" "static" {
  for_each = local.students
  name = "deceptor-fgt-${each.value.name}-pip"
}


# Create FGTVM compute instance
resource "google_compute_instance" "fortigate" {
  for_each = local.students
  name           = "deceptor-fgt-${each.value.name}"
  machine_type   = var.machine
  zone           = var.zone
  can_ip_forward = "true"

  tags = ["allow-fgt", "allow-internal", "${each.value.name}"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  attached_disk {
    source = google_compute_disk.logdisk["${each.value.name}"].name
  }
  network_interface {
    subnetwork = google_compute_subnetwork.untrust.name
    /* network_ip = "${each.value.p1ip}" */
    access_config {
          nat_ip = google_compute_address.static["${each.value.name}"].address
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.trust["${each.value.name}"].name
    network_ip = "${each.value.p2ip}"
  }

    network_interface {
    subnetwork = google_compute_subnetwork.tools["${each.value.name}"].name
    network_ip = "${each.value.p3ip}"
  }

  metadata = {
    user-data = data.template_file.fgt_userdata["${each.value.name}"].rendered
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  scheduling {
    preemptible       = false
    automatic_restart = false
  }
}

data "template_file" "fgt_userdata" {
  template = file("./fgt.tpl")
  for_each = local.students
  vars = {
    fgt_id = "${each.value.name}"
    trust_sub = "${each.value.trust_range}"
    tools_sub = "${each.value.tools_range}"
  }
}

# Create kali compute instance
resource "google_compute_instance" "kali" {
  for_each = local.students
  name           = "deceptor-kali-${each.value.name}"
  machine_type   = var.machine
  zone           = var.zone
  can_ip_forward = "false"

  tags = ["allow-internal", "${each.value.name}"]

  boot_disk {
    initialize_params {
      image = var.kali-image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.trust["${each.value.name}"].name
    network_ip = "${each.value.kalip}"
  }
 }

# Create deceptor compute instance
resource "google_compute_instance" "deceptor" {
  for_each = local.students
  name           = "deceptor-${each.value.name}"
  machine_type   = var.deceptor_machine
  zone           = var.zone
  can_ip_forward = "false"

  tags = ["allow-fgt", "allow-internal", "${each.value.name}"]

  boot_disk {
    initialize_params {
      image = var.deceptor_image
    }
  }
  attached_disk {
    source = google_compute_disk.deceptordisk["${each.value.name}"].name
  }
  network_interface {
    subnetwork = google_compute_subnetwork.tools["${each.value.name}"].name
    network_ip = "${each.value.decp1}"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.trust["${each.value.name}"].name
    network_ip = "${each.value.decp2}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  scheduling {
    preemptible       = false
    automatic_restart = false
  }
}




output "fortigate_name" {
  value = toset([
    for fortigate in google_compute_instance.fortigate : fortigate.name
  ])
}

output "nat_ip" {
  value = toset([
    for fortigate in google_compute_instance.fortigate : fortigate.network_interface.0.access_config.0.nat_ip
  ])
}

output "FortiGate-Username" {
  value = "admin"
}

output "fgt_password" {
  value = toset([
    for fortigate in google_compute_instance.fortigate : fortigate.instance_id
  ])
}
