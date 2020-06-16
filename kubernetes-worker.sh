#!/bin/bash
echo "Setting variables"
IP_MASTER=10.128.0.9
HOSTNAME_MASTER=kubernetes-master-1
IP_WORKER=10.128.0.8
HOSTNAME_WORKER=kubernetes-worker-1
echo "Configuring"
swapoff -a
hostnamectl set-hostname ${HOSTNAME}
cat << FOE >> /etc/hosts
${IP_MASTER} ${HOSTNAME_MASTER}
${IP_WORKER} ${HOSTNAME_WORKER}
FOE
echo "# Install Docker CE"
echo "## Set up the repository:"
echo "### Install packages to allow apt to use a repository over HTTPS"
apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common
echo "### Add Docker’s official GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "### Add Docker apt repository."
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io
echo "# Setup daemon."
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
echo "# Restart docker."
systemctl enable docker.service
systemctl start docker.service
# echo "# Adding User."
# sudo groupadd docker
# sudo usermod -aG docker $USER

echo "Installing Kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository \
    "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
#export KUBECONFIG=/etc/kubernetes/admin.conf
#kubeadm init  --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.182.0.4
#echo "Deploying Kubernetes (with Calico)"
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
#echo "Configuring for not root user"
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config
#export KUBECONFIG=$HOME/.kube/config
vim vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
systemctl daemon-reload
kubeadm join 10.128.0.9:6443 --token y1fdnb.jvs0cew7a9d4k5rs --discovery-token-ca-cert-hash sha256:098eaa73eda4e8b2a4920ce1e5343c2179ac3167ebab712528eac27d07e341fb