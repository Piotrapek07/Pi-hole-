# Sprawdzenie czy skrypt został uruchomiony jako administrator
if [ "$(id -u)" -ne 0 ]; then
  echo -e "\e[1mProszę uruchom ten skrypt jako administrator (używając sudo)\e[0m"
  exit 1  
fi

# Pobieranie informacji o adresie IP, bramie domyślnej i masce sieciowej
read -p "Podaj adres IP: " IP
read -p "Podaj adres bramy domyślnej: " GATEWAY
read -p "Podaj maskę sieci: " NETMASK

# Automatyczne pobranie nazwy interfejsu sieciowego (ignorowanie loopback)
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

# Sprawdzenie, czy jest więcej niż jeden interfejs
num_interfaces=$(echo "$interfaces" | wc -l)
if [ "$num_interfaces" -eq 1 ]; then
    # Jeśli jest tylko jeden interfejs, użyj go automatycznie
    enp="$interfaces"
else
    # Jeśli jest więcej niż jeden interfejs, zapytaj użytkownika, który chce użyć
    echo "Dostępne interfejsy sieciowe:"
    echo "$interfaces"
    read -p "Podaj nazwę interfejsu sieciowego: " enp
fi

# Zapisanie konfiguracji 
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

# Zastosowanie nowej konfiguracji
netplan apply

