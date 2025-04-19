#!/bin/bash

# Étape 1 : Installation des dépendances
sudo apt update
sudo apt install -y docker.io containerd buildah podman openssl

# Étape 2 : Démarrage d’un registre Docker local
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Étape 3 : Génération de clés RSA
openssl genrsa -out MyPrivateKey.pem 2048
openssl rsa -in MyPrivateKey.pem -pubout -out MyPublicKey.pem

# Étape 4 : Création d’une image Docker simple
echo "SuperSecretFlag{12345}" > secretFlag

cat <<EOF > Dockerfile
FROM nginx:latest
COPY secretFlag /secretFlag
EOF

# Étape 5 : Chiffrement et push de l’image
curl http://localhost:5000/v2/_catalog

sudo buildah bud -t encrypted_docker_image .

sudo buildah push --tls-verify=false \
--encryption-key jwe:/chemin/vers/MyPublicKey.pem \
encrypted_docker_image \
docker://localhost:5000/dockrypt/encrypted_docker_image:latest

curl http://localhost:5000/v2/_catalog

# Étape 6 : Pull et déchiffrement de l’image
sudo buildah rmi --all

sudo buildah pull localhost:5000/dockrypt/encrypted_docker_image:latest

sudo buildah pull --tls-verify=false \
--decryption-key /chemin/vers/MyPrivateKey.pem \
docker://localhost:5000/dockrypt/encrypted_docker_image:latest

sudo podman run -it localhost:5000/dockrypt/encrypted_docker_image:latest /bin/bash
