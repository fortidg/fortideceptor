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
  access_token = var.token
}
provider "google-beta" {
  project      = var.project
  region       = var.region
  zone         = var.zone
  access_token = var.token
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
  name = "log-disk-${random_string.random_name_post.result}"
  size = 30
  type = "pd-standard"
  zone = var.zone
}


### VPC ###
resource "google_compute_network" "untrust" {
  name                    = "untrust-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

resource "google_compute_network" "trust" {
  name                    = "trust-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

resource "google_compute_network" "tools" {
  name                    = "tools-${random_string.random_name_post.result}"
  auto_create_subnetworks = false
}

### Public Subnet ###
resource "google_compute_subnetwork" "untrust" {
  name                     = "untrust-subnet-${random_string.random_name_post.result}"
  region                   = var.region
  network                  = google_compute_network.untrust.name
  ip_cidr_range            = var.public_subnet
  private_ip_google_access = true
}
### Private Subnet ###
resource "google_compute_subnetwork" "trust" {
  name          = "trust-subnet-${random_string.random_name_post.result}"
  region        = var.region
  network       = google_compute_network.trust.name
  ip_cidr_range = var.protected_subnet
}

### Tools Subnet ###
resource "google_compute_subnetwork" "tools" {
  name          = "trust-subnet-${random_string.random_name_post.result}"
  region        = var.region
  network       = google_compute_network.tools.name
  ip_cidr_range = var.tools_subnet
}

resource "google_compute_route" "default-trust" {
  name        = "default-trust"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.trust.name
  next_hop_ip = var.fgt_port2_ip
  priority    = 100
  depends_on  = [google_compute_subnetwork.trust]
}

resource "google_compute_route" "default-tools" {
  name        = "default-tools"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.tools.name
  next_hop_ip = var.fgt_port3_ip
  priority    = 100
  depends_on  = [google_compute_subnetwork.tools]
}

# Firewall Rule External
resource "google_compute_firewall" "allow-all-fgt" {
  name    = "allow-fgt-${random_string.random_name_post.result}"
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
  name    = "allow-internal-${random_string.random_name_post.result}"
  network = google_compute_network.trust.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-internal"]
}

# Firewall Rule Tools
resource "google_compute_firewall" "allow-tools" {
  name    = "allow-tools-${random_string.random_name_post.result}"
  network = google_compute_network.tools.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-internal"]
}

# Create Static Public IP
resource "google_compute_address" "static" {
  name = "deceptor-fgt-${random_string.random_name_post.result}-pip"
}

# Create second Static Public IP
resource "google_compute_address" "static2" {
  name = "deceptor-fgt-${random_string.random_name_post.result}-pip2"
}


# Create FGTVM compute instance
resource "google_compute_instance" "fortigate" {
  name           = "decptor-fgt-${random_string.random_name_post.result}"
  machine_type   = var.machine
  zone           = var.zone
  can_ip_forward = "true"

  tags = ["allow-fgt", "allow-internal"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  attached_disk {
    source = google_compute_disk.logdisk.name
  }
  network_interface {
    subnetwork = google_compute_subnetwork.untrust.name
    access_config {
          nat_ip = google_compute_address.static.address
    }
    access_config {
          nat_ip = google_compute_address.static2.address
    }
  }
  
  network_interface {
    subnetwork = google_compute_subnetwork.trust.name
    network_ip = var.fgt_port2_ip
  }

    network_interface {
    subnetwork = google_compute_subnetwork.tools.name
    network_ip = var.fgt_port3_ip
  }


  metadata = {
    user-data = "${file(var.user_data)}"
    user-data = fileexists("${path.module}/${var.user_data}") ? "${file(var.user_data)}" : null
    #license   = "${file(var.license_file)}" #this is where to put the license file if using BYOL image
    license = fileexists("${path.module}/${var.license_file}") ? "${file(var.license_file)}" : null
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

# Create kali compute instance
resource "google_compute_instance" "kali" {
  name           = "deceptor-kali-${random_string.random_name_post.result}"
  machine_type   = var.machine
  zone           = var.zone
  can_ip_forward = "false"

  tags = ["allow-internal"]

  boot_disk {
    initialize_params {
      image = var.kali-image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.trust.name
    network_ip = var.kali_ip
  }

  /* metadata_startup_script = data.template_file.linux-metadata.rendered */
}

# Bootstrapping Script to Install Apache
/* data "template_file" "linux-metadata" {
template = <<EOF
#!/bin/bash
## add student1 user, make them sudoer and allow pasword auth
/usr/sbin/useradd student1
echo student1:Fortinet1! | chpasswd
usermod -aG sudo student1
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo service sshd restart
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Wait for Internet access through the FGTs"
while ! curl --connect-timeout 3 "http://www.google.com" &> /dev/null
    do continue
done
apt-get update -y
#install nodejs and npm
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash - &&\
apt-get install -y nodejs
#install juice shop
git clone https://github.com/juice-shop/juice-shop.git --depth 1
cd juice-shop
npm install
npm start
cd
EOF
} */

# Create windows compute instance
resource "google_compute_instance" "win" {
  name           = "deceptor-win-${random_string.random_name_post.result}"
  machine_type   = var.win-machine
  zone           = var.zone
  can_ip_forward = "false"

  tags = ["allow-internal"]

  boot_disk {
    initialize_params {
      image = var.win-image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.trust.name
    network_ip = var.win_ip
  }

  /* metadata_startup_script = data.template_file.linux-metadata.rendered */
}

# Output
output "FortiGate-NATIP" {
  value = google_compute_instance.fortigate.network_interface.0.access_config.0.nat_ip
}
output "FortiGate-InstanceName" {
  value = google_compute_instance.fortigate.name
}
output "FortiGate-Username" {
  value = "admin"
}
output "FortiGate-Password" {
  value = google_compute_instance.fortigate.instance_id
}
