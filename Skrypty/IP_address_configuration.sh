if [ "$(id -u)" -ne 0 ]; then
  echo -e "\e[1mProszę uruchom ten skrypt jako administrator (używając sudo)\e[0m"
  exit 1  
fi

read -p "Podaj adres IP: " IP
read -p "Podaj adres bramy domyślnej: " GATEWAY
read -p "Podaj maskę sieci: " NETMASK

interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

num_interfaces=$(echo "$interfaces" | wc -l)
if [ "$num_interfaces" -eq 1 ]; then
    enp="$interfaces"
else
    echo "Dostępne interfejsy sieciowe:"
    echo "$interfaces"
    read -p "Podaj nazwę interfejsu sieciowego: " enp
fi

cat > /etc/netplan/01-network-manager-all.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $enp:
      addresses: [$IP/$NETMASK]
      gateway4: $GATEWAY
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF

netplan apply

