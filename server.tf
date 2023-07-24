
resource "digitalocean_droplet" "infra_manager" {
  image  = "ubuntu-22-10-x64"
  name   = "infra-manager"
  region = "sgp1" // 싱가포르 리전으로 변경
  # size   = "s-1vcpu-1gb"
  size = "s-2vcpu-4gb"
  user_data = file("terraform-digitalocean-infra-manager.yaml")

  connection {
    host = self.ipv4_address // 수정된 부분
    type = "ssh"
    user = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    timeout     = "2m"
  }

  provisioner "file" {
    source      = "sshd_config"
    destination = "/tmp/sshd_config"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown root:root /tmp/sshd_config",
      "sudo cp /tmp/sshd_config /etc/ssh/sshd_config",
    ]
  }
}

resource "digitalocean_domain" "internal_domain" {
  name = var.internal_domain
}

resource "digitalocean_record" "a_record" {
  domain = digitalocean_domain.internal_domain.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.infra_manager.ipv4_address
}

resource "null_resource" "infra_manager" {
  depends_on = [ digitalocean_droplet.infra_manager ]

  provisioner "local-exec" {
    command = <<EOF
      echo "[infra-manager-main]" > inventory
      echo "${digitalocean_droplet.infra_manager.ipv4_address} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa" >> inventory
      ssh-keyscan ${digitalocean_droplet.infra_manager.ipv4_address} >> $HOME/.ssh/known_hosts
      sed -i ''-e '/server\.team/d' ~/.ssh/known_hosts
      sed -i ''-e '/api\.team/d' ~/.ssh/known_hosts
      sed -i ''-e '/server\.kebal/d' ~/.ssh/known_hosts
      sed -i ''-e '/api\.kebal/d' ~/.ssh/known_hosts
      EOF
  }
}

resource "null_resource" "credentials" {
  depends_on = [ null_resource.infra_manager ]

  provisioner "local-exec" {
    command = <<EOF
	  echo "---\n${local.credentials_yml_content}" | tee credentials.yaml > /dev/null
	EOF
  }

  triggers = {
  	internal_domain = var.internal_domain
	postgres_root_password = var.postgres_root_password
  }
}
