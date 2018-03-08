# terraform-aws-openshift

## bastion
```
scp -i key_pare.pem key_pare.pem ec2-user@bastion.local:/.ssh/id_rsa

ssh -i key_pare.pem ec2-user@bastion.local
```

## install 1 master
```
curl -s toast.sh/install-v3 | bash

export DOMAIN=nalbam.com
export DISK=/dev/sdf

sudo ~/toaster/openshift/install.sh
```

## install 1 master 2 node
```
scp -i keys/_key_pairs/nalbam-seoul.pem keys/_key_pairs/nalbam-seoul.pem ec2-user@13.125.153.54:~/.ssh/id_rsa
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@13.125.153.54 -t 'curl -s toast.sh/install-v3 | bash'

ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@13.125.153.54 -t '~/toaster/openshift/install-bastion.sh'
```

## console
* https://console.nalbam.com:8443/

## reference
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
