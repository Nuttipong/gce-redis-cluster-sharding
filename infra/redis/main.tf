# data "template_file" "init" {
#   template = file("./redis/template/create-cluster.tpl")
#   vars = {
#     ips = google_compute_instance.instances[*].network_interface.0.access_config.0.nat_ip,
#   }
# }

resource "null_resource" "cluster" {
  depends_on = [google_compute_instance.instances]
  connection {
    type        = "ssh"
    user        = "nuttipong_tae"
    host        = google_compute_instance.instances[0].network_interface.0.access_config.0.nat_ip
    private_key = "${file("~/.ssh/gcp-ssh")}"
    timeout     = "10s"
  }

  provisioner "remote-exec" {
    inline = [
      "redis-cli -a a-very-complex-password-here --cluster create ${google_compute_instance.instances[0].network_interface.0.access_config.0.nat_ip}:7000 ${google_compute_instance.instances[1].network_interface.0.access_config.0.nat_ip}:7000 ${google_compute_instance.instances[2].network_interface.0.access_config.0.nat_ip}:7000 ${google_compute_instance.instances[3].network_interface.0.access_config.0.nat_ip}:7000 ${google_compute_instance.instances[4].network_interface.0.access_config.0.nat_ip}:7000 ${google_compute_instance.instances[5].network_interface.0.access_config.0.nat_ip}:7000 --cluster-replicas 1 --cluster-yes"
    ]
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = google_compute_instance.instances[0].network_interface.0.access_config.0.nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  # metadata = {
  #   ssh-keys = "nuttipong_tae:${file("~/.ssh/gcp-ssh.pub")}"
  # }
}

resource "google_compute_instance" "instances" {
  count        = length(var.nodes)
  name         = "redis${count.index + 1}"
  machine_type = var.nodes[count.index].machine_type
  zone         = var.nodes[count.index].zone
  tags         = var.nodes[count.index].tags

  # metadata_startup_script = data.template_file.init.rendered

  # provisioner "local-exec" {
  #   command = data.template_file.init.rendered
  # }

  provisioner "file" {
    source = "../config/redis/6.0/rc.local"
    destination = "/tmp/rc.local"
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  provisioner "file" {
    source = "../config/redis/6.0/sysctl.conf"
    destination = "/tmp/sysctl.conf"
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  provisioner "file" {
    source = "../config/redis/6.0/redis_7000.conf"
    destination = "/tmp/redis_7000.conf"
    
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  provisioner "file" {
    source = "../config/redis/6.0/redis_7000.service"
    destination = "/tmp/redis_7000.service"
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install redis-server",
      "ps -f -u redis",
      "sudo systemctl disable redis-server.service",
      "sudo ufw allow 7000",
      "sudo ufw allow 17000",
      "sudo mkdir /etc/redis/cluster",
      "sudo mkdir /etc/redis/cluster/7000",
      "sudo mkdir /var/lib/redis/7000",
      "sudo cp /tmp/rc.local /etc/rc.local",
      "sudo cp /tmp/sysctl.conf /etc/",
      # "sudo echo vm.overcommit_memory=1 >> /etc/sysctl.conf",
      "sudo cp /tmp/redis_7000.conf /etc/redis/cluster/7000/redis_7000.conf",
      "sudo cp /tmp/redis_7000.service /etc/systemd/system/redis_7000.service",
      "sudo chmod +x /etc/rc.local",
      "sudo chown redis:redis -R /var/lib/redis",
      "sudo chmod 770 -R /var/lib/redis",
      "sudo chown redis:redis -R /etc/redis",
      "sudo systemctl enable /etc/systemd/system/redis_7000.service",
      "sudo reboot"
    ]
    connection {
      type        = "ssh"
      user        = "nuttipong_tae"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = "${file("~/.ssh/gcp-ssh")}"
    }
  }

  boot_disk {
    initialize_params {
      image = "${var.nodes[count.index].image_project}/${var.nodes[count.index].image_family}"
    }
  }

  network_interface {
    network = var.nodes[count.index].subnet
    access_config { }
  }

  metadata = {
    ssh-keys = "nuttipong_tae:${file("~/.ssh/gcp-ssh.pub")}"
  }
}

resource "google_compute_firewall" "rules" {
  project     = var.project_id
  name        = "redis-rule"
  network     = "default"
  description = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports     = ["80", "22", "7000", "17000"]
  }

  source_tags = []
  target_tags = ["redis-tag"]
}