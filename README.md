# 🔐 Déploiement Sécurisé d’une Image Docker avec Chiffrement JWE

Ce script Bash automatise la création, le chiffrement, le déploiement et l'exécution d’une image Docker en utilisant `Buildah`, `Podman` et un registre Docker local. Il met en œuvre un chiffrement **JWE (JSON Web Encryption)** avec des clés RSA.

## 🛠 Prérequis

- Ubuntu (ou autre distribution Linux compatible)
- Droits sudo
- Paquets installés automatiquement :
  - `docker.io`
  - `containerd`
  - `buildah`
  - `podman`
  - `openssl`
  - `curl`

## 📄 Fichier : `deploy_secure_docker.sh`

### Étapes automatisées par le script :

1. **Mise à jour du système et installation des dépendances**
2. **Lancement d’un registre Docker local** sur le port `5000`
3. **Génération de paires de clés RSA** si elles n’existent pas (`MyPrivateKey.pem`, `MyPublicKey.pem`)
4. **Création d’un fichier secret** (`secretFlag`) à inclure dans l’image
5. **Génération d’un Dockerfile** simple basé sur l’image `nginx`
6. **Construction de l’image Docker** avec `buildah`
7. **Tag de l’image pour le registre local**
8. **Push de l’image chiffrée dans le registre local** (chiffrement via la clé publique RSA)
9. **Vérification que l’image est bien poussée**
10. **Suppression des images locales** pour simuler un test de récupération
11. **Pull et déchiffrement de l’image depuis le registre** (clé privée requise)
12. **Exécution du conteneur avec Podman**

## 🔐 Chiffrement JWE

Le chiffrement est réalisé à l’aide de :
- `--encryption-key jwe:MyPublicKey.pem` pour chiffrer au push
- `--decryption-key MyPrivateKey.pem` pour déchiffrer au pull

## 🚀 Lancer le script

```bash
chmod +x deploy_secure_docker.sh
./deploy_secure_docker.sh

