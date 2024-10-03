if [ "$(id -u)" -ne 0 ]; then
  echo -e "\e[1mProszę uruchom ten skrypt jako administrator (używając sudo)\e[0m"
  exit 1  
fi

progress_bar() {
  local current="$1"
  local total="$2"
  local max_width=50
  local progress=$((current * max_width / total))
  local percentage=$((current * 100 / total))
  
  printf "\r%s\n[%-${max_width}s] %3d%%" "$operation" "$(printf '#%.0s' $(seq 1 "$progress"))" "$percentage"
}

completed_operations=0

total_operations=3

while true; do
  operation="Aktualizacja list pakietów..."
  echo -n "$operation"
  sudo apt update >/dev/null 2>&1
  completed_operations=$((completed_operations + 1))
  progress_bar "$completed_operations" "$total_operations"
  echo
  
  operation="Aktualizacja pakietów..."
  echo -n "$operation"
  sudo apt upgrade -y >/dev/null 2>&1
  completed_operations=$((completed_operations + 1))
  progress_bar "$completed_operations" "$total_operations"
  echo
  
  operation="Instalacja curl..."
  echo -n "$operation"
  sudo apt install curl -y >/dev/null 2>&1
  completed_operations=$((completed_operations + 1))
  progress_bar "$completed_operations" "$total_operations"
  echo
  
  if [ "$completed_operations" -eq "$total_operations" ]; then
    break
  fi
done

curl -sSL https://install.pi-hole.net | bash

echo ""
echo "--------------------------------------------------"
echo "\033[1mWpisz nowe hasło dla pihole\033[0m"
echo "--------------------------------------------------"
echo ""
sudo pihole -a -p

sudo apt install unbound
sudo cat >> /etc/unbound/unbound.conf.d/pi-hole.conf << EOF
server:
    # If no logfile is specified, syslog is used
    # logfile: "/var/log/unbound/unbound.log"
    verbosity: 0

    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # May be set to yes if you have IPv6 connectivity
    do-ip6: no

    # You want to leave this to no unless you have *native* IPv6. With 6to4 and
    # Terredo tunnels your web browser should favor IPv4 for the same reasons
    prefer-ip6: no

    # Use this only when you downloaded the list of primary root servers!
    # If you use the default dns-root-data package, unbound will find it automatically
    root-hints: "/var/lib/unbound/root.hints"

    # Trust glue only if it is within the server's authority
    harden-glue: yes

    # Require DNSSEC data for trust-anchored zones, if such data is absent, the zone becomes BOGUS
    harden-dnssec-stripped: yes

    # Don't use Capitalization randomization as it known to cause DNSSEC issues sometimes
    # see https://discourse.pi-hole.net/t/unbound-stubby-or-dnscrypt-proxy/9378 for further details
    use-caps-for-id: no

    # Reduce EDNS reassembly buffer size.
    # IP fragmentation is unreliable on the Internet today, and can cause
    # transmission failures when large DNS messages are sent via UDP. Even
    # when fragmentation does work, it may not be secure; it is theoretically
    # possible to spoof parts of a fragmented DNS message, without easy
    # detection at the receiving end. Recently, there was an excellent study
    # >>> Defragmenting DNS - Determining the optimal maximum UDP response size for DNS <<<
    # by Axel Koolhaas, and Tjeerd Slokker (https://indico.dns-oarc.net/event/36/contributions/776/)
    # in collaboration with NLnet Labs explored DNS using real world data from the
    # the RIPE Atlas probes and the researchers suggested different values for
    # IPv4 and IPv6 and in different scenarios. They advise that servers should
    # be configured to limit DNS messages sent over UDP to a size that will not
    # trigger fragmentation on typical network links. DNS servers can switch
    # from UDP to TCP when a DNS response is too big to fit in this limited
    # buffer size. This value has also been suggested in DNS Flag Day 2020.
    edns-buffer-size: 1232

    # Perform prefetching of close to expired message cache entries
    # This only applies to domains that have been frequently queried
    prefetch: yes

    # One thread should be sufficient, can be increased on beefy machines. In reality for most users running on small networks or on a single machine, it should be unnecessary to seek performance enhancement by increasing num-threads above 1.
    num-threads: 1

    # Ensure kernel buffer is large enough to not lose messages in traffic spikes
    so-rcvbuf: 1m

    # Ensure privacy of local IP ranges
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10
EOF
sudo service unbound restart

sudo cat > /etc/cron.d/pihole << EOF
# Pi-hole: A black hole for Internet advertisements
# (c) 2017 Pi-hole, LLC (https://pi-hole.net)
# Network-wide ad blocking via your own hardware.
#
# Updates ad sources every week
#
# This file is copyright under the latest version of the EUPL.
# Please see LICENSE file for your rights under this license.
#
#
#
# This file is under source-control of the Pi-hole installation and update
# scripts, any changes made to this file will be overwritten when the software
# is updated or re-installed. Please make any changes to the appropriate crontab
# or other cron file snippets.

# Pi-hole: Update the ad sources once a week on Sunday at a random time in the
#          early morning. Download any updates from the adlists
#          Squash output to log, then splat the log to stdout on error to allow for
#          standard crontab job error handling.
0 */6  * * *   root    PATH="$PATH:/usr/sbin:/usr/local/bin/" pihole updateGravity >/var/log/pihole/pihole_updateGravity.log || cat /var/log/pihole/pihole_updateGravity.log

# Pi-hole: Flush the log daily at 00:00
#          The flush script will use logrotate if available
#          parameter "once": logrotate only once (default is twice)
#          parameter "quiet": don't print messages
00 00   * * *   root    PATH="$PATH:/usr/sbin:/usr/local/bin/" pihole flush once quiet

@reboot root /usr/sbin/logrotate --state /var/lib/logrotate/pihole /etc/pihole/logrotate

# Pi-hole: Grab remote and local version every 24 hours
13 18  * * *   root    PATH="$PATH:/usr/sbin:/usr/local/bin/" pihole updatechecker
@reboot root    PATH="$PATH:/usr/sbin:/usr/local/bin/" pihole updatechecker reboot
EOF
sudo service cron reload


