#!/bin/bash
echo "--- Starting k3s custom route setup ---"
ip link add dummy0 type dummy || true # attempt to prevent failures that cause may crash on or shortly after boot
ip link set dev dummy0 up
ip addr add 203.0.113.254/31 dev dummy0
ip route add default via 203.0.113.255 dev dummy0 metric 100
echo "--- k3s custom routes successfully established ---"
