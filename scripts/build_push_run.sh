#!/bin/bash

set -e

echo "[*] Construction de l'image Docker encryptée avec Buildah..."

# Créer un fichier secret
echo "SuperSecretFlag{12345}" > secretFlag

# Créer le Dockerfile
cat <<EOF > Dockerfile
FROM docker.io/library/nginx:latest
COPY secretFlag /secretFlag
EOF

# Construction de l'image
sudo buildah bud -t encrypted_docker_image .

# Tag de l'image
sudo buildah tag encrypted_docker_image localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Push de l'image encryptée vers le registre local sécurisé..."
sudo buildah push --tls-verify=false \
  --encryption-key jwe:./MyPublicKey.pem \
  localhost:5000/dockrypt/encrypted_docker_image:latest \
  docker://localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Suppression locale des images pour test de pull..."
sudo buildah rmi -a

echo "[*] Pull et déchiffrement de l'image depuis le registre local..."
sudo buildah pull --tls-verify=false \
  --decryption-key ./MyPrivateKey.pem \
  docker://localhost:5000/dockrypt/encrypted_docker_image:latest

echo "[*] Exécution de l'image déchiffrée avec Podman..."
sudo podman run -it localhost:5000/dockrypt/encrypted_docker_image:latest /bin/bash

echo "[+] Build, push, pull et run terminés."
