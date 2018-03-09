# terraform-aws-openshift

## install : 1 master
```
export master_ip="13.125.198.132"

scp -i keys/_key_pairs/nalbam-seoul.pem keys/_key_pairs/nalbam-seoul.pem ec2-user@${master_ip}:~/.ssh/id_rsa
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${master_ip} -t 'curl -s toast.sh/install-v3 | bash'
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${master_ip} -t 'sudo ~/toaster/openshift/install2.sh'
```

## install : 1 bastion, 1 master, 2 node
```
export bastion_ip="13.125.153.54"

scp -i keys/_key_pairs/nalbam-seoul.pem keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip}:~/.ssh/id_rsa
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip} -t 'curl -s toast.sh/install-v3 | bash'
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip} -t '~/toaster/openshift/install-bastion.sh'
```

## console
* https://console.nalbam.com:8443/

## reference
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
