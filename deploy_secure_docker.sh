#!/bin/bash

set -e  # Stopper le script en cas d’erreur

echo "[*] Étape 1 : Mise à jour et installation des dépendances..."
sudo apt update
sudo apt install -y docker.io containerd buildah podman openssl curl

echo "[*] Étape 2 : Démarrage du registre Docker local..."
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2

echo "[*] Étape 3 : Génération des clés RSA (si non existantes)..."
if [[ ! -f MyPrivateKey.pem || ! -f MyPublicKey.pem ]]; then
  openssl genrsa -out MyPrivateKey.pem 2048
  openssl rsa -in MyPrivateKey.pem -pubout -out MyPublicKey.pem
else
  echo "[+] Les clés existent déjà, on les conserve."
fi

echo "[*] Étape 4 : Création du fichier secret..."
echo "SuperSecretFlag{12345}" > secretFlag

echo "[*] Étape 5 : Création du Dockerfile..."
cat <<EOF > Dockerfile
FROM docker.io/library/nginx:latest
COPY secretFlag /secretFlag
EOF

echo "[*] Étape 6 : Construction de l’image Docker avec Buildah..."
sudo buildah bud -t encrypted_docker_image .

echo "[*] Étape 7 : Tag de l’image avant le push..."
sudo buildah tag encrypted_docker_image localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Étape 8 : Push de l’image chiffrée dans le registre local..."
sudo buildah push --tls-verify=false \
  --encryption-key jwe:./MyPublicKey.pem \
  localhost:5000/dockrypt/encrypted_docker_image:latest \
  docker://localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Étape 9 : Vérification de la présence de l’image dans le registre..."
curl -s http://localhost:5000/v2/_catalog

echo "[*] Étape 10 : Suppression des images locales pour test pull + déchiffrement..."
sudo buildah rmi -a

echo "[*] Étape 11 : Pull et déchiffrement de l’image depuis le registre..."
sudo buildah pull --tls-verify=false \
  --decryption-key ./MyPrivateKey.pem \
  docker://localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Étape 12 : Exécution du conteneur avec Podman..."
sudo podman run -it localhost:5000/dockrypt/encrypted_docker_image:latest /bin/bash

