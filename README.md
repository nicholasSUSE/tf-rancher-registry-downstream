# Terraform EC2 Rancher Downstream

Debug Default Private Registry problem with `Rancher2` provider `rancher2_app_v2` resource.

---

## Client Architecture

```mermaid
flowchart TB
    subgraph TERRAFORM
        direction LR
        subgraph AWS
            direction LR
            subgraph ec2#1
                direction BT
                subgraph k3s
                    direction BT
                    subgraph local-cluster
                        rancher-->defaultSystemRegistry
                    end
                end
            end
            subgraph ec2#2
                direction BT
                subgraph RKE
                    direction BT
                    subgraph docker.
                        direction BT
                        subgraph Downstream_Cluster
                            ControlPlane
                            etcD
                            Worker
                        end
                    end
                end
            end
            subgraph ec2#3
                subgraph docker
                    direction BT
                    id1[(Private-Registry)]
                end
            end
            subgraph ec2#4
                subgraph docker_
                    direction BT
                    id2[(Global-Default-Registry)]
                end
            end
        end
    end
    Downstream_Cluster <--> local-cluster
    defaultSystemRegistry --> id2[(Global-Default-Registry)]
    Downstream_Cluster --> id1[(Private-Registry)]
    id1[(Private-Registry)] --> id2[(Global-Default-Registry)]
```

---

# Debugging Minimal Architecture

```mermaid
flowchart TB
    subgraph TERRAFORM
        direction TB
        subgraph AWS
            direction TB
            subgraph ec2#1
                direction TB
                subgraph k3s
                    direction TB
                    subgraph local-cluster
                        rancher-->defaultSystemRegistry
                    end
                end
            end
            subgraph ec2#2
                direction LR
                subgraph RKE
                    direction LR
                    subgraph docker.
                        direction LR
                        subgraph Downstream_Cluster
                            id2(((rancher2_app_v2 - CIS Benchmark)))
                            Worker
                            ControlPlane
                            etcD
                        end
                    end
                end
            end
            subgraph RandomURL
            end
            subgraph ec2#3
                subgraph docker
                    direction LR
                    id1[(Private-Registry)]
                end
            end
        end
    end
    Downstream_Cluster <--> local-cluster
    defaultSystemRegistry --> RandomURL
    Downstream_Cluster --> id1[(Private-Registry)]
    id1[(Private-Registry)] --> id2(((rancher2_app_v2 - CIS Benchmark)))
```


## System Images and Private Registries within Rancher.

We have our 4 main Helm chart repositories:
- `rke2`
- `rancher-charts`
- `partner-charts`
- `system-charts`

We have the `system images`, some of these images are inside `rancher-charts` repository and some under the `system-charts`.
They are used for Rancher system operation, they are not installable by user actions, instead user actions may result in their installation.

i.e:
1. If you install `cis-benchmark` chart from the Rancher UI.
2. The following system images will be installed automatically or have to be already installed previously:
    - `rancher/cis-operator:v1.0.12`
    - `rancher/kubectl:v1.26.3`


These necessary `system images` for each Rancher version can be downloaded on the Github Rancher Releases.

e.g:
1. https://github.com/rancher/rancher/releases
2. Assets
3. `rancher-images.txt`

The `rancher-images.txt` for Rancher v2.7.9 has up to 720 images.
Rancher does not install all of them but they are all shipped with Rancher and depending on user actions some might be installed and some not.

The minimum amount and the requiredd images for Rancher to work is something like this:
```
rancher/rancher:v2.7.5
rancher/shell:v0.1.20
rancher/webhook-receiver:v0.2.5
rancher/rancher-agent:v2.7.5
rancher/rancher-webhook:v0.3.5
rancher/fleet-agent:v0.7.0
rancher/fleet:v0.7.0
rancher/gitjob:v0.1.54
rancher/nginx-ingress-controller:nginx-1.7.0-rancher1
rancher/mirrored-nginx-ingress-controller-defaultbackend:1.5-rancher1
rancher/nginx-ingress-controller:nginx-1.5.1-rancher2
rancher/system-agent-installer-k3s:v1.25.9-k3s1
rancher/k3s-upgrade:v1.25.9-k3s1
rancher/rancher-agent:v2.7.5
rancher/istio-installer:1.17.2-rancher1
rancher/istio-kubectl:1.5.10
rancher/kubectl:v1.26.3
rancher/library-nginx:1.19.2-alpine
rancher/rancher-csp-adapter:v2.0.2
rancher/externalip-webhook:v1.0.1
rancher/flannel-cni:v0.3.0-rancher8
rancher/system-agent-installer-rke2:v1.25.9-rke2r1
rancher/system-agent:v0.3.3-suc
rancher/rke-tools:v0.1.88
rancher/rke-tools:v0.1.89
rancher/rke-tools:v0.1.90
rancher/hyperkube:v1.25.9-rancher2
rancher/mirrored-coreos-etcd:v3.5.6
rancher/mirrored-calico-apiserver:v3.25.0
rancher/mirrored-calico-cni:v3.25.0
rancher/mirrored-calico-ctl:v3.25.0
rancher/mirrored-calico-kube-controllers:v3.25.0
rancher/mirrored-calico-node:v3.25.0
rancher/mirrored-calico-pod2daemon-flexvol:v3.25.0
rancher/mirrored-calico-typha:v3.25.0
rancher/mirrored-coredns-coredns:1.10.1
rancher/mirrored-coreos-flannel:v0.15.1
rancher/mirrored-k8s-dns-kube-dns:1.22.20
rancher/mirrored-k8s-dns-node-cache:1.22.20
rancher/mirrored-k8s-dns-sidecar:1.22.20
rancher/mirrored-k8s-dns-dnsmasq-nanny:1.22.20
rancher/mirrored-cluster-proportional-autoscaler:1.8.6
docker.io/rancher/klipper-helm:v0.7.7-build20230403
docker.io/rancher/klipper-lb:v0.4.3
docker.io/rancher/local-path-provisioner:v0.0.24
docker.io/rancher/mirrored-coredns-coredns:1.10.1
docker.io/rancher/mirrored-library-busybox:1.34.1
docker.io/rancher/mirrored-library-traefik:2.9.4
docker.io/rancher/mirrored-metrics-server:v0.6.2
docker.io/rancher/mirrored-pause:3.6
docker.io/rancher/mirrored-pause:3.7

```


## Code Explanation

At `instances.tf` we have all EC2 Instances:
- resource "aws_instance" "default_registry"
- resource "aws_instance" "rancher_server"
- resource "aws_instance" "bug_node"

These instances are created with the necessary power and HD space for running Rancher, Downstream Clusters and Private Registry.

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

One common code between all of them is the `cloud-init` package:

This package contains utilities for early initialization, it is the industry standard for multi-distribution, closs-platform cloud instance initialization.

Normally it is used for:
- supported across all major public cloud-providers
- set up default locale
- set up hostname
- generate and set up SSH private keys
- init network instance
- set up ephemeral mount points

#### Default Registry Instance
We upload 3 files and execute 1 script right after the the `cloud-init` package.

- `./scripts/userdata_default_registry.template`:
    - executed right after cloud-init
    - generates a self-signed certificate specifically for the `default_registry` IPv4 DNS.
    - set up the self-signed certificate for the EC2 instance and Docker
    - Runs the `private_registry` docker container with the self-signed certificate.
    - executes Rancher Private Registry files to `pull`, `tag` and `push` the images to the docker running container.
- `./files/rancher-images.txt`: This is not the original file I have modified it with only the necessary images to install App `cis-benchmark` in order to reproduce the bug.
- `./files/rancher-load-images.sh`: Original Rancher provided script for pulling images from `rancher-images.txt`.
- `./files/rancher-save-images.sh`: Original Rancher provided script for tagging and pushing images to the running docker container.

> We also upload the `./scripts/manage_default_registry.sh`, but this is only used for debugging and updating the private registry without having to restart the entire instance when needed.

```
  provisioner "file" {
    source      = "${path.module}/files/rancher-images.txt"
    destination = "/home/ubuntu/rancher-images.txt"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/rancher-load-images.sh"
    destination = "/home/ubuntu/rancher-load-images.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/rancher-save-images.sh"
    destination = "/home/ubuntu/rancher-save-images.sh"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  user_data = templatefile(
    "${path.module}/scripts/userdata_default_registry.template",
    {}
  )
```

Once the `Default Registry Instance` and the `Private Registry Container` inside it are up and running, we download to the local machine the `generated self-signed certificate` that we created at `./scripts/userdata_default_registry.template`:
```
resource "null_resource" "scp_file" {
  depends_on = [ aws_instance.default_registry ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/ec2_download_cert.sh ${aws_instance.default_registry.public_dns}"
  }
}
```

> This will be used by the other instances that may want to connect to this private registry like (`bug_node` instance), without it we would have a TLS error.

#### Bug Node Instance

This instance will hold the `Managed Downstream Cluster` that will try to connect to the `Private Registry`, so we need to wait for:
- `Default Registry Instance` is running
- `Private Registry Container` is running
- `Private Registry Container` is populated
- `Self-Signed certificate` is downloaded locally

Than we can upload the downloaded self-signed certificate with:
```
  provisioner "file" {
    source      = "${path.module}/certs/domain.crt"
    destination = "/home/ubuntu/domain.crt"

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }
```


---

# How to execute and validate

1. Run `terraform init && terraform apply --auto-approve` with this `system_default_registry` attribute commented:
    ```(hcl) node_bug.tf
    #----------------------------------------------------------------
    # Comment/Uncomment the following to enable/disable the bug
    #----------------------------------------------------------------
    # Wait for cluster to be ready before creating any apps on it
    resource "rancher2_cluster_sync" "bug_sync" {
    provider = rancher2.BUG
    depends_on = [ null_resource.bug_node_cmd ]
    cluster_id = rancher2_cluster.bug_cluster.id

    timeouts {
        create = "5m"
        update = "5m"
        delete = "5m"
    }
    }

    # Create Rancher-CIS-Benchark App from Helm chart
    resource "rancher2_app_v2" "cis_benchmark_bug_cluster" {
    provider = rancher2.BUG

    depends_on = [
        rancher2_cluster_sync.bug_sync,
        aws_instance.default_registry
    ]

    cluster_id = rancher2_cluster_sync.bug_sync.cluster_id
    name = "rancher-cis-benchmark"
    namespace = "cis-operator-system"
    repo_name = "rancher-charts"
    chart_name = "rancher-cis-benchmark"
    cleanup_on_fail = true
    wait = false

    # comment/uncomment to reproduce/disable the bug
    # system_default_registry = "${aws_instance.default_registry.public_dns}:5000"
    timeouts {
        create = "3m"
        update = "3m"
        delete = "3m"
    }
    }

    output "system_default_registry" {
    value = rancher2_app_v2.cis_benchmark_bug_cluster.system_default_registry
    }
    ```
2. Wait for it to deploy and check if everything is working:
    - [X] Rancher server
    - [X] Downstream Cluster
3. Uncomment the previous section and `terraform apply --auto-approve` again.
4. Check at:
    - [X] Mapps > Installed Apps > CIS Operator failure with URL prefix must point to the Private Registry DNS
        - ```system_default_registry = "${aws_instance.default_registry.public_dns}:5000"```

---

## Using Custom Rancher2 Provider

1. Create `~/.terraformrc` file with:
    ```
    provider_installation {
    dev_overrides {
        "rancher/rancher2" = "<path_to_your_>/<terraform-bug-project>/bin"
    }
    direct {}
    }
    ```
2. Clone: https://github.com/rancher/terraform-provider-rancher2
    - `make build`
    - copy --> paste `terraform-provider-rancher2/bin/ --> [terraform-bug-project]/bin`
3. Destroy everything and start from scratch:
    - `terraform destroy --auto-approve`
    - `terraform init -reconfigure`
4. Run with Custom Built Provider: `terraform apply --auto-approve`

## Debugging Utilities

### K3s Images for Bundled mode

```
curl -L "https://github.com/k3s-io/k3s/releases/download/v1.25.9+k3s1/k3s-images.txt" -o files/k3s-images.txt --compressed

curl -L "https://github.com/k3s-io/k3s/releases/download/v1.25.9+k3s1/k3s-airgap-images-${ARCH}.tar" -o files/k3s-airgap-images-amd64.tar


docker run -d --restart=always \
    -p 5000:5000 \
    --name "defaultregistry" \
    -v /home/ubuntu/volume:/var/lib/registry \
    registry:2


helm template "files/cert-manager-v1.12.3.tgz" | \
        awk '$1 ~ /image:/ {print $2}' | sed s/\"//g >> files/rancher-images.txt
```

#### Get cloud-init provisioner logs

```
tail -f /var/log/cloud-init-output.log -n 100000
```

---

#### HTTPS + SSL at Private Registry

Generate the Self-signed certificate at the Private Registry Machine:
```
echo "Generating TLS certificates"
mkdir -p /home/ubuntu/certs
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /home/ubuntu/certs/domain.key -x509 -days 365 -out /home/ubuntu/certs/domain.crt -subj "/CN=$PUBLIC_DNS"

echo "creating volume dir at /home/ubuntu"
sudo mkdir -p /home/ubuntu/volume
echo "changing permissions"
sudo chmod +rw /home/ubuntu/volume

echo "Running Docker Registry with TLS"
docker run -d --restart=always \
        -p 5000:5000 \
        --name "defaultregistry" \
        -v /home/ubuntu/volume:/var/lib/registry \
        -v /home/ubuntu/certs:/certs \
        -e REGISTRY_HTTP_ADDR=0.0.0.0:5000 \
        -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
        -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
        registry:2
```

Copy these certificates to all Rancher Cluster managed nodes.

See if the certificate is right:
```
openssl x509 -in ./certs/domain.crt -text -noout
```

---

### Node Command Example
```
sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.7.5 --server https://rancher.18.117.168.196.sslip.io --token kmkflxhwjfcf5scbjcsrr7kmh59kqj78wtdnmz7mhlnc6fp7zq6dnc --ca-checksum 5f8b308fa5f88fdc12749aa991901e54784ec61b36255319bdcf4d00d3734433"

# structured
sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes \
    -v /var/run:/var/run  ec2-18-217-230-142.us-east-2.compute.amazonaws.com:5000/rancher/rancher-agent:v2.7.5 \
    --server https://rancher.18.116.40.118.sslip.io \
    --token n22wlx598kkpln557kmnxrtkjrzfjgpgf25dxs59hl4kx4m92564lf \
    --ca-checksum 093ba96bbdf7ae1c690f03fec2380fb4ee1a08eceea7d28a761032ecd0c65f8d \
    --address $publicIP --internal-address $privateIP --controlplane --etcd --worker

# calling
./bug_node_cmd.sh 'sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  ec2-13-58-41-102.us-east-2.compute.amazonaws.com:5000/rancher/rancher-agent:v2.7.5 --server https://rancher.18.221.171.6.sslip.io --token rf4wqd87tcb624wtccp6jk2ctr727mkcbn9d5ds5kwxlqdcdmbwj8q --ca-checksum 509c80f314180181359b9602e3a50a86f9c32fe99ded149356a9a0f24a1e704c' ec2-13-58-41-102.us-east-2.compute.amazonaws.com:5000

```

### Testing connectivity from Bug Node -> Private Registry:
```
docker pull ec2-3-144-6-67.us-east-2.compute.amazonaws.com:5000/rancher/fleet-agent:v0.7.0

curl --insecure https://PUBLIC_DNS:5000/v2/_catalog

curl -v ec2-18-216-242-109.us-east-2.compute.amazonaws.com:5000/v2/rancher/fleet-agent/manifests/v0.7.0
```

---

## Debugging RKE containers

```
# see the logs
docker logs kube-apiserver
docker logs kube-controller-manager
docker logs kube-scheduler
docker logs kubelet

# save locally the logs
docker logs kube-apiserver > kube-apiserver.txt
docker logs kube-controller-manager > kube-controller-manager.txt
docker logs kube-scheduler > kube-scheduler.txt
docker logs kubelet > kubelet.txt

# download from ec2
scp -i ./certs/id_rsa ubuntu@ec2-18-226-150-187.us-east-2.compute.amazonaws.com:~/kube-apiserver.txt .
scp -i ./certs/id_rsa ubuntu@ec2-18-226-150-187.us-east-2.compute.amazonaws.com:~/kube-controller-manager.txt .
scp -i ./certs/id_rsa ubuntu@ec2-18-226-150-187.us-east-2.compute.amazonaws.com:~/kube-scheduler.txt .
scp -i ./certs/id_rsa ubuntu@ec2-18-226-150-187.us-east-2.compute.amazonaws.com:~/kubelet.txt .

# get inside the containers
docker exec -it  kube-apiserver /bin/sh
docker exec -it  kube-controller-manager /bin/sh
docker exec -it  kube-scheduler /bin/sh
docker exec -it  kubelet /bin/sh

# see events
kubectl get events --all-namespaces
```

---

# Log Debugging - RKE Containers

### `kube-controller-manager Error:`

```
error retrieving resource lock kube-system/kube-controller-manager: Get "https://127.0.0.1:6443/apis/coordination.k8s.io/v1/namespaces/kube-system/leases/kube-controller-manager?timeout=5s": dial tcp 127.0.0.1:6443: connect: connection refused
```

This is often a sign that the API server is not running or not accessible at the expected address.

### `kube-apiserver Error:`

shows a warning related to the etcd client:

```
"retrying of unary invoker failed".
```

Might be connectivity issues with the etcd server, which is critical for the API server's operation.

The API server relies on etcd for storing all cluster data.

### `kube-scheduler Error:`

```
(dial tcp 127.0.0.1:6443: connect: connection refused).
```

API server is either down or not reachable.

### `kubelet Error:`

```
The kubelet log Failed to create sandbox for pod...manifest for [registry URL]/rancher/mirrored-pause:3.7 not found: manifest unknown:
```

Issue with pulling a required image from your private registry.

The `mirrored-pause image` is a basic container used by Kubernetes for various internal operations.

If the kubelet can't pull this image, it won't be able to start any pods.
