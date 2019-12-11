provider "nutanix" {
  username  = var.nutanix_user
  password  = "Ch@nd792!"
  endpoint  = "10.0.1.40"
  insecure  = true
  port      = 9440
}

data "nutanix_clusters" "clusters" {
}

locals {
  cluster1 = data.nutanix_clusters.clusters.entities[1].metadata.uuid
}

### Image Data Sources
data "nutanix_image" "Windows_10_Disk" {
     #metadata = {
         #kind = "image"
     #}
   image_id = "ace1ae3a-67e9-4af1-9733-00f09499e87f"
  #image_id = nutanix_image.Windows_10_Disk.id
  }


# ###  Define Terraform Managed Subnets
resource "nutanix_subnet" "TF-managed-network-500" {
  cluster_uuid = local.cluster1
  name        = "TF-managed-network-500"
  vlan_id     = 500
  subnet_type = "VLAN"
  subnet_ip = "10.0.5.0"
  default_gateway_ip = "10.0.5.1"
  prefix_length      = 24

  dhcp_options = {
    boot_file_name   = "bootfile"
    domain_name      = "internal.shizman.com"
  }

  dhcp_server_address = {
    ip = "10.0.5.254"
  }

  dhcp_domain_name_server_list = ["10.0.1.100"]
  dhcp_domain_search_list      = ["internal.shizman.com"]
  ip_config_pool_list_ranges   = ["10.0.5.3 10.0.5.253"] 
}

resource "nutanix_virtual_machine" "TF-demo-01" {
  name                 = "TF-demo-01"
  description          = "Demo Terraform VM"
  num_vcpus_per_socket = 2
  num_sockets          = 1
  memory_size_mib      = 4096

  cluster_uuid = local.cluster1

  
  nic_list {
    subnet_uuid = nutanix_subnet.TF-managed-network-500.id
  }

  disk_list {
    data_source_reference = {
        kind = "image"
        uuid = "ace1ae3a-67e9-4af1-9733-00f09499e87f"
      }
      
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }

      device_type = "DISK"
    }
  }
  
  }
  
output "ip_address" {
  value = nutanix_virtual_machine.TF-demo-01.nic_list_status.0.ip_endpoint_list[0]["ip"]
}
