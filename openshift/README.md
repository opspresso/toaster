# terraform-aws-openshift

## bastion
```
scp -i key_pare.pem key_pare.pem ec2-user@bastion.local:/.ssh/id_rsa

ssh -i key_pare.pem ec2-user@bastion.local
```

## install from bastion
```
curl -s toast.sh/install-v3 | bash

export DOMAIN=nalbam.com
export DISK=/dev/sdf

sudo ~/toaster/openshift/install.sh
```

## console
* https://console.nalbam.com:8443/

## reference
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
