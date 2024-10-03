# Sprawdzenie czy skrypt został uruchomiony jako administrator
if [ "$(id -u)" -ne 0 ]; then
  echo -e "\e[1mProszę uruchom ten skrypt jako administrator (używając sudo)\e[0m"
  exit 1  
fi

# Nadanie uprawnień dla plików
echo ""
echo "--------------------------------------------------"
echo "\033[1mNadanie uprawnień dla plików\033[0m"
echo "--------------------------------------------------"
echo ""
chmod +x IP_address_configuration.sh
chmod +x Pi-hole_installation_and_main_configuration.sh

# Włączenie skryptu odpowiedzialnego za konfigurację IP
echo ""
echo "-------------------------------------------------------"
echo "\033[1mWłączenie skryptu odpowiedzialnego za konfigurację IP\033[0m"
echo "-------------------------------------------------------"
echo ""
sudo ./IP_address_configuration.sh

# Włączenie skryptu odpowiedzialnego za instalację i konfigurację Pi-hole
echo ""
echo "------------------------------------------------------------------------"
echo "\033[1mWłączenie skryptu odpowiedzialnego za instalację i konfigurację Pi-hole\033[0m"
echo "------------------------------------------------------------------------"
echo ""
sudo ./Pi-hole_installation_and_main_configuration.sh