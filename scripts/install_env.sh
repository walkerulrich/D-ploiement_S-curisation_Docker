#!/bin/bash

set -e

echo "[*] Installation des dépendances système..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg git nano make golang-1.21

echo "[*] Installation de kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

echo "[*] Installation de Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo "[*] Installation de Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

echo "[*] Démarrage du cluster Minikube..."
minikube start --network-plugin=cni --enable-default-cni --container-runtime=containerd --bootstrapper=kubeadm --insecure-registry="172.16.25.62:5000"

echo "[*] Clonage de l'opérateur IBM pour la synchronisation de clé..."
git clone https://github.com/IBM/k8s-enc-image-operator.git
cd k8s-enc-image-operator

echo "[*] Création du namespace my-key-sync..."
kubectl create namespace my-key-sync

echo "[*] Déploiement de l'opérateur avec Helm..."
helm install --namespace=my-key-sync k8s-enc-image-operator ./helm-operator/helm-charts/enckeysync/

echo "[*] Ajout du secret de clé privée dans Kubernetes..."
kubectl create -n my-key-sync secret generic --type=key --from-file=/home/studentlab/Documents/Project_Dockcript/MyKey/MyPrivateKey.pem k8s-decrypt-key

echo "[*] Configuration du module de décryption (ctd-decoder) dans Minikube..."
minikube ssh << EOF
git clone https://github.com/containerd/imgcrypt.git
cd imgcrypt && make
sudo cp bin/ctd-decoder /usr/local/bin/
sudo chmod +x /usr/local/bin/ctd-decoder

sudo tee -a /etc/containerd/config.toml > /dev/null <<EOT

[plugins."io.containerd.grpc.v1.cri".image_decryption]
  key_model = "node"

[stream_processors]
  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
    returns = "application/vnd.oci.image.layer.v1.tar+gzip"
    path = "/usr/local/bin/ctd-decoder"
    args = ["--decryption-keys-path", "/etc/crio/keys/enc-key-sync/6f9f04014499229ad6303a01d3958a08-enc-key-sync-k8s-decrypt-key-MyPrivateKey.pem"]

  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
    accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
    returns = "application/vnd.oci.image.layer.v1.tar"
    path = "/usr/local/bin/ctd-decoder"
    args = ["--decryption-keys-path", "/etc/crio/keys/enc-key-sync/6f9f04014499229ad6303a01d3958a08-enc-key-sync-k8s-decrypt-key-MyPrivateKey.pem"]
EOT

sudo systemctl restart containerd
EOF

echo "[+] Installation terminée."
