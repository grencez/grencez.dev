---
canonical_url: https://grencez.dev/2018/ssl-dehydrated-20180812
date: 2018-08-12
last_modified_at: 2021-01-18
description: How to  programs from source in Linux as a normal user with GNU Stow.
---

# Generate a Signed SSL Certificate

Date: 2018-08-12

Update: 2021-01-18

If your website doesn't use SSL (HTTPS), then it should!
Without SSL, someone on the network can see exactly what a user is doing on the site.
For security, a trusted third party has to vouch for your public SSL key so that users know they are talking to your site.
This page gives you easy-mode Linux commands to set up SSL with the following steps:

1. Use the [Dehydrated](https://dehydrated.io) client to:
   1. Prove to the [Let's Encrypt](https://letsencrypt.org) that you own `$domain` by putting a certain files in `http://$domain/.well-known/acme-challenge/`.
   1. Generate an SSL certificate.
   1. Get it signed by Let's Encrypt.
1. Install the new certificate.

- [Initial Setup](#initial)
  - [Create "Well-Known" Directory](#mkdir)
  - [Get Dehydrated Client](#download)
  - [Create Config Files](#config)
- [Recurring Process](#process)
  - [Run Dehydrated](#run)
  - [Install Certificate (lighttpd)](#lighttpd)
  - [Install Certificate (CPanel)](#cpanel)

## Initial Setup {#initial}

### Create "Well-Known" Directory {#mkdir}

On your webserver, create the directory to host `http://$domain/.well-known/acme-challenge/`.

```shell
ssh $domain
domain=yourdomain.net
public_html="/srv/$domain/http"
mkdir -p "$public_html/.well-known/acme-challenge"
```

Did that last command need root privileges?
Let's use `sudo` to create it and give our non-root user ownership so we don't have to run `dehydrated` as root.

```shell
sudo mkdir -p "$public_html/.well-known/acme-challenge"
sudo chown $USER:$USER "$public_html/.well-known/acme-challenge"
```

Now make sure it works:

```shell
echo "hello world" > "$public_html/.well-known/acme-challenge/hello.txt"
chmod a+r "$public_html/.well-known/acme-challenge/hello.txt"
curl "$domain/.well-known/acme-challenge/hello.txt"
rm "$public_html/.well-known/acme-challenge/hello.txt"
```

Did "hello world" print on the terminal?
If so, great!
If not, please make it work before proceeding.

### Get Dehydrated Client {#download}

Next grab the Dehydrated client.
Ideally you should run this on your server, but it's not strictly necessary.

```shell
cd $HOME/Downloads/
git clone https://github.com/dehydrated-io/dehydrated.git
cd dehydrated
```

### Create Config Files {#config}

Next we need 2 config files to tell `dehydrated` what domain you own (`domains.txt`) and what "well-known" directory you'll use to prove it (`config.sh`).

```shell
echo "$domain www.$domain" > domains.txt
echo "WELLKNOWN=$public_html/.well-known/acme-challenge" > config.sh
```

## Recurring Process {#process}

You'll want to regenerate a new certificate every 2 months so it doesn't expire (after 3 months).

### Run Dehydrated {#run}

If on your webserver, just run:

```shell
git pull  # stay up to date
./dehydrated -c -f config.sh
```

If running from your local machine, make `$public_html` accessible via `sshfs` first.

```shell
mkdir -p public_html
sshfs $domain:$public_html public_html
echo "WELLKNOWN='$PWD/public_html/.well-known/acme-challenge'" > config.sh
git pull  # stay up to date
./dehydrated -c -f config.sh
fusermount -u public_html
```

### Install Certificate (lighttpd) {#lighttpd}

```shell
cat "certs/$domain/cert.pem" "certs/$domain/privkey.pem" > mynewcert.pem
sudo install -m 640 -o root -g root mynewcert.pem "/etc/lighttpd/certs/$domain.pem"
rm mynewcert.pem
```

### Install Certificate (CPanel) {#cpanel}

I (used to) have to go to `http://$domain/cpanel`, login, click SSL/TLS, click Install and Manage SSL, select my domain, and then copy/paste the `cert.pem` and `privkey.pem` files into the Certificate and Private Key fields.
The file contents can quickly be copied using the first two `xsel` commands.

```shell
cat "certs/$domain/cert.pem" | xsel -b
cat "certs/$domain/privkey.pem" | xsel -b
echo 'nothing to see here' | xsel -b  # Clear the clipboard selection.
```

Those `xsel` commands don't work on a webserver, but you can just as easily type `ssh $domain cat "path/to/dehydrated/certs/$domain/cert.pem" | xsel -b` from your own machine.
