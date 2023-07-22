# mediasvr-pull
Self-provisioning server that replicates my media server setup



1. Create CoreOS machine
2. Install CoreOS with ```sudo coreos-install install -I https://raw.githubusercontent.com/cfios4/ignition.ign```
3. Install k3s ```curl -fsSL https://get.k3s.io | sh -```
4. Apply manifests with ```kubectl apply -f https://raw.githubusercontent.com/cfios4/manifests/...```
