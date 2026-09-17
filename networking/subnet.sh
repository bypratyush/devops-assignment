#!/usr/bin/env bash
# subnet.sh - IP addressing and subnetting, calculated rather than recited.
#   ./subnet.sh 192.168.10.0/26
set -u

calc() {
  local cidr="$1"
  local ip="${cidr%/*}" prefix="${cidr#*/}"
  local host_bits=$(( 32 - prefix ))
  local total=$(( 2 ** host_bits ))
  local usable=$(( total > 2 ? total - 2 : 0 ))

  # netmask from the prefix length
  local mask_int=$(( 0xFFFFFFFF ^ ((1 << host_bits) - 1) ))
  [ "$prefix" -eq 0 ] && mask_int=0
  local m1=$(( (mask_int >> 24) & 255 )) m2=$(( (mask_int >> 16) & 255 ))
  local m3=$(( (mask_int >> 8) & 255 ))  m4=$(( mask_int & 255 ))

  # ip -> integer
  local IFS=.; read -r a b c d <<< "$ip"; unset IFS
  local ip_int=$(( (a << 24) + (b << 16) + (c << 8) + d ))
  local net_int=$(( ip_int & mask_int ))
  local bcast_int=$(( net_int | ((1 << host_bits) - 1) ))
  int2ip() { printf '%d.%d.%d.%d' $(( ($1>>24)&255 )) $(( ($1>>16)&255 )) $(( ($1>>8)&255 )) $(( $1&255 )); }

  # address class from the first octet
  local class
  if   [ "$a" -le 127 ]; then class="A"
  elif [ "$a" -le 191 ]; then class="B"
  elif [ "$a" -le 223 ]; then class="C"
  elif [ "$a" -le 239 ]; then class="D (multicast)"
  else class="E (experimental)"; fi

  # RFC1918 private ranges
  local scope="PUBLIC"
  if   [ "$a" -eq 10 ]; then scope="PRIVATE (10.0.0.0/8)"
  elif [ "$a" -eq 172 ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]; then scope="PRIVATE (172.16.0.0/12)"
  elif [ "$a" -eq 192 ] && [ "$b" -eq 168 ]; then scope="PRIVATE (192.168.0.0/16)"
  elif [ "$a" -eq 127 ]; then scope="LOOPBACK"
  elif [ "$a" -eq 169 ] && [ "$b" -eq 254 ]; then scope="LINK-LOCAL (APIPA)"; fi

  printf "  %-22s %s\n" "input"            "$cidr"
  printf "  %-22s %s\n" "class"            "$class"
  printf "  %-22s %s\n" "scope"            "$scope"
  printf "  %-22s %d.%d.%d.%d\n" "subnet mask" "$m1" "$m2" "$m3" "$m4"
  printf "  %-22s %d network / %d host\n" "bits" "$prefix" "$host_bits"
  printf "  %-22s %s\n" "network address"  "$(int2ip $net_int)"
  printf "  %-22s %s\n" "broadcast address" "$(int2ip $bcast_int)"
  if [ "$usable" -gt 0 ]; then
    printf "  %-22s %s - %s\n" "usable host range" "$(int2ip $((net_int + 1)))" "$(int2ip $((bcast_int - 1)))"
  else
    printf "  %-22s none (too small)\n" "usable host range"
  fi
  printf "  %-22s 2^%d = %s\n" "total addresses" "$host_bits" "$total"
  printf "  %-22s 2^%d - 2 = %s   (network + broadcast are reserved)\n" "usable hosts" "$host_bits" "$usable"
  echo
}

if [ $# -gt 0 ]; then
  for c in "$@"; do calc "$c"; done
else
  echo "=============================================================="
  echo " SUBNET CALCULATIONS"
  echo "=============================================================="
  echo
  for c in 120.27.1.0/8 197.23.45.10/24 192.168.10.0/26 10.244.0.0/16 172.16.5.0/20 192.168.1.1/32; do
    calc "$c"
  done
fi
