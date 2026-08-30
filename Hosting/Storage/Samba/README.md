# Partage SMB (dynamis + loki)

Un seul service en `mode: global`. Ce qui le rend spécifique à chaque serveur,
ce sont deux montages dont le **chemin est identique mais le contenu local** :

| Montage | Effet |
|---|---|
| `/mnt:/shares` | chaque noeud n'expose que les disques qu'il possède |
| `/mnt/volume/Samba/smb.conf` | déclare les partages propres à ce serveur |

Même principe que `portainer-agent` avec `/var/run/docker.sock`.

## Déploiement de la configuration

Les `smb.conf` de ce dépôt sont la source de vérité. Ils doivent être copiés
vers `/mnt/volume/Samba/smb.conf` sur le serveur correspondant.

```bash
# sur dynamis (le dépôt y est déjà cloné par Portainer)
sudo mkdir -p /mnt/volume/Samba
sudo cp Hosting/Storage/Samba/dynamis/smb.conf /mnt/volume/Samba/smb.conf

# sur loki (Portainer ne clone que sur le manager, donc copie depuis dynamis)
ssh loki 'sudo mkdir -p /mnt/volume/Samba'
scp Hosting/Storage/Samba/loki/smb.conf loki:/tmp/smb.conf
ssh loki 'sudo mv /tmp/smb.conf /mnt/volume/Samba/smb.conf'
```

> **Le fichier doit exister avant le premier déploiement.** Docker qui
> bind-monte un fichier absent crée un *dossier* à sa place, et l'initialisation
> du conteneur échoue de façon peu lisible.

Après modification d'un `smb.conf`, recopier puis forcer le redémarrage :

```bash
docker service update --force host-storage-samba_samba
```

## Prérequis : désactiver le smbd natif

Le Samba natif occupe déjà le port 445 sur les deux serveurs. À faire sur
**dynamis et loki** :

```bash
systemctl status smbd nmbd            # état avant
sudo systemctl disable --now smbd nmbd
sudo ss -tlnp | grep -E ':(139|445)'  # doit ne plus rien retourner
```

Le module de partage de fichiers de Cockpit ne pilotera plus rien après ça.
C'est voulu : c'est lui qui appliquait la configuration au mauvais serveur
lorsque les deux hôtes étaient réunis dans une seule interface Cockpit.

## Comptes

Les mots de passe se saisissent dans Portainer (Stack -> Environment
variables), jamais dans ce dépôt. Voir `.env.example`.

| Compte | Accès |
|---|---|
| `pisel` | tous les partages, les deux serveurs |
| `media` | partage `media` de dynamis uniquement |

`UID_media` doit correspondre à l'UID Linux réel du compte sur dynamis
(`id <compte>`), sinon les droits sur les fichiers ne suivront pas.

## Validation d'une configuration

```bash
docker run --rm -v /chemin/vers/smb.conf:/tmp/smb.conf:ro \
  --entrypoint testparm \
  ghcr.io/servercontainers/samba:smbd-wsdd2-a3.24.1-s4.23.8-r0 -s /tmp/smb.conf
```
