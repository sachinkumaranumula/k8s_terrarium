resource "google_compute_instance_template" "k8s_node_template" {
  name                 = "k8s-node-template"
  description          = "This template is used to create k8s cluster nodes"
  instance_description = "k8s cluster node"
  machine_type         = "e2-small" //2vCPU, 2GB

  // Create a new boot disk from an image
  disk {
    source_image = "ubuntu-2004-focal-v20231213"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.k8s_network.self_link
    subnetwork = google_compute_subnetwork.k8s_subnet.self_link
  }

  service_account {
    email  = google_service_account.k8s_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "google_compute_instance_from_template" "k8s_cp1" {
  name                     = "vm-k8scp-dev-001"
  tags                     = ["k8s-cp"]
  source_instance_template = google_compute_instance_template.k8s_node_template.self_link

  metadata = {
    enable-oslogin = "TRUE"
    user-data      = "${data.cloudinit_config.cp_cloud_config.rendered}"
  }

}

resource "google_compute_instance_from_template" "k8s_worker1" {
  name                     = "vm-k8sw-dev-001"
  tags                     = ["k8s-worker"]
  source_instance_template = google_compute_instance_template.k8s_node_template.self_link

  metadata = {
    enable-oslogin = "TRUE"
    user-data      = "${data.cloudinit_config.node_cloud_config.rendered}"
  }

}

# https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config
data "cloudinit_config" "node_cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content      = templatefile("${path.module}/files/base-cloud-config.tpl", { node_name = "worker-1", ip_address = "<ip_address>" })
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content      = templatefile("${path.module}/files/node-cloud-config.tpl", {})
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
  }
}

data "cloudinit_config" "cp_cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content      = templatefile("${path.module}/files/base-cloud-config.tpl", { node_name = "master-1", ip_address = "<ip_address>" })
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content      = templatefile("${path.module}/files/node-cloud-config.tpl", {})
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content      = templatefile("${path.module}/files/cp-cloud-config.tpl", { node_name = "master-1", cluster_cidr_range = "<cidr_range>" })
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}
