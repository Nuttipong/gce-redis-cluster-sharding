gcp_project_id = "tdg-ct-carbontrace-nonprod-brx"
# gce_ssh_user = ""
# gce_ssh_pub_key_file_path = "/Users/nuttipongtaechasanguanwong/Workspace/gce-redis-cluster/tdg-ct-carbontrace-nonprod-brx-8fc68b01960d.json"
nodes = [
    {
        zone            = "asia-southeast1-a"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
    {
        zone            = "asia-southeast1-b"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
    {
        zone            = "asia-southeast1-c"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
    {
        zone            = "asia-southeast1-a"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
    {
        zone            = "asia-southeast1-b"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
    {
        zone            = "asia-southeast1-c"
        machine_type    = "n1-standard-1"
        image_family    = "ubuntu-2004-lts"
        image_project   = "ubuntu-os-cloud"
        tags            = ["redis-tag"]
        subnet          = "default"
    },
]