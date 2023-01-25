#!/bin/bash
echo "🔑 Creating temporary ssh key"
ssh-keygen -f ./k8s-goof-key -b 2048 -q -N ""
echo -n "   ▪ "; civo sshkey create k8s-goof-key -k ./k8s-goof-key.pub | grep -v "api.github.com"

LOCAL_IP="$(curl -s ifconfig.co/)/32"
echo "🔥 Creating firewall to limit ingress from only $LOCAL_IP"
echo -n "   ▪ "; civo firewall create k8s-goof-fw --create-rules=false | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p TCP -c $LOCAL_IP | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p UDP -c $LOCAL_IP | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p ICMP -c $LOCAL_IP | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p TCP -d egress | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p UDP -d egress | grep -v "api.github.com"
echo -n "   ▪ "; civo firewall rule create k8s-goof-fw -s=1 -e=65535 -p ICMP -d egress | grep -v "api.github.com"

echo "🔨 Provisioning instance"
echo -n "  ▪ "; civo instance create -s k8s-goof -u ubuntu -i g3.medium -k k8s-goof-key -l k8s-goof-fw --diskimage=ubuntu-jammy --script ./vm-init.sh -w -p=create | grep -v "api.github.com"

PUBLIC_IP="$(civo instance show k8s-goof -o custom -f public_ip | tail -1)"

echo -n "⌚️ Waiting for demo app to become available (at $PUBLIC_IP)..."
while ! curl -s http://$PUBLIC_IP/webadmin
do
  sleep 5
  echo -n "."
done

echo "🥳 Done!"
echo
echo "😈 Vulnerable app running at http://$PUBLIC_IP/webadmin"
echo "💻 Shell access via: ssh ubuntu@$PUBLIC_IP -i k8s-goof-key"
