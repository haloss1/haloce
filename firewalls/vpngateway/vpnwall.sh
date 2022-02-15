sysctl -w net.ipv6.conf.all.disable_ipv6=1 
sysctl -w net.ipv6.conf.default.disable_ipv6=1 
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
sysctl -w net.ipv4.ipfrag_low_thresh=0
sysctl -w net.ipv4.ipfrag_high_thresh=0
sysctl -w net.ipv4.ipfrag_time=0
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.core.netdev_max_backlog=4000
wait
sleep 1
ipset create LEGIT hash:ip,port timeout 10
ipset create TEST2 hash:ip timeout 30
ipset create TEST1 hash:ip timeout 60
ipset create MDNS hash:ip
# ipset create CLIENTS hash:net
# ipset add CLIENTS 10.0.0.1/24
wait
ipset add MDNS 54.82.252.156
ipset add MDNS 34.197.71.170
# ipset add MDNS 1.1.1.1
# ipset add MDNS haloserverpublicip
wait
iptables -t raw -N ctest2
iptables -t raw -N pcheck
iptables -t raw -N madmins
iptables -t mangle -N reconnect
# iptables -t raw -A PREROUTING -i eth0 -p udp --dport 51820 -m set --match-set MDNS src -j ACCEPT
iptables -t raw -A PREROUTING -i eth0 -p udp --dport 51820 -j ACCEPT
iptables -t raw -A PREROUTING -i eth0 -m set --match-set LEGIT src,src -j ACCEPT
iptables -t raw -A PREROUTING -i eth0 -m set --match-set TEST1 src -j pcheck
iptables -t raw -A PREROUTING -i eth0 -m set --match-set MDNS src -j madmins
iptables -t raw -A PREROUTING -i eth0 -m length --length 48 -m u32 --u32 "42=0x1333360c" -j pcheck
iptables -t raw -A PREROUTING -i eth0 -m length --length 67 -m u32 --u32 "28=0xfefe0100" -j ctest2
iptables -t raw -A PREROUTING -i eth0 -m length ! --length 34 -j DROP
iptables -t raw -A PREROUTING -i eth0 -m u32 ! --u32 "28=0x5C717565" -j DROP
iptables -t raw -A PREROUTING -i eth0 -j ctest2
iptables -t raw -A pcheck -p udp --sport 0 -j DROP
iptables -t raw -A pcheck ! -p udp -j DROP
iptables -t raw -A pcheck -p udp ! --dport 2302:2502 -j DROP
iptables -t raw -A pcheck -j SET --exist --add-set TEST1 src
iptables -t raw -A pcheck -m u32 --u32 "42=0x1333360c" -j ACCEPT
iptables -t raw -A pcheck -m set --match-set TEST2 src -j ctest2
iptables -t raw -A pcheck -m u32 --u32 "28=0x5C717565" -j ctest2
iptables -t raw -A pcheck -m set --match-set LEGIT src,src -j ACCEPT
iptables -t raw -A pcheck -m u32 ! --u32 "34&0xFFFFFF=0xFFFFFF" -j DROP
iptables -t raw -A pcheck -j SET --exist --add-set TEST2 src
iptables -t raw -A pcheck -j ACCEPT
iptables -t raw -A ctest2 -p udp --sport 0 -j DROP
iptables -t raw -A ctest2 ! -p udp -j DROP
iptables -t raw -A ctest2 -p udp ! --dport 2302:2502 -j DROP
iptables -t raw -A ctest2 -j SET --exist --add-set TEST1 src
iptables -t raw -A ctest2 -j SET --exist --add-set TEST2 src
iptables -t raw -A ctest2 -m u32 --u32 "28=0xfefe0100" -j SET --exist --add-set LEGIT src,src
iptables -t raw -A ctest2 -m set --match-set LEGIT src,src -j ACCEPT
iptables -t raw -A ctest2 -m u32 --u32 "28=0x5C717565" -j ACCEPT
iptables -t raw -A ctest2 -m u32 --u32 "42=0x1333360c" -j ACCEPT
iptables -t raw -A ctest2 -m u32 --u32 "34&0xFFFFFF=0xFFFFFF" -j ACCEPT
iptables -t raw -A ctest2 -j DROP
iptables -t raw -A madmins -s 34.197.71.170 -j ACCEPT
iptables -t raw -A madmins -s 54.82.252.156 -j ACCEPT
iptables -t raw -A madmins -p tcp -j ACCEPT
iptables -t raw -A madmins -p udp --dport 3389 -j ACCEPT
iptables -t raw -A madmins -p udp -j pcheck
iptables -t mangle -A PREROUTING -i eth0 -m set --match-set LEGIT src,src -j SET --exist --add-set LEGIT src,src
iptables -t mangle -A PREROUTING -i eth0 -m length --length 31 -m set --match-set LEGIT src,src -m u32 --u32 "27&0x00FFFFFF=0x00fefe68" -j reconnect
iptables -t mangle -A reconnect -j SET --del-set TEST1 src
iptables -t mangle -A reconnect -j SET --del-set LEGIT src,src
iptables -t nat -A PREROUTING -i eth0 -m udp -p udp --dport 2302 -j DNAT --to-destination 10.0.0.2:2302
iptables -t nat -A PREROUTING -i eth0 -m udp -p udp --dport 2304:2504 -j DNAT --to-destination 10.0.0.4:2304-2504
iptables -t nat -A PREROUTING -i eth0 -m tcp -p tcp --dport 3389 -j DNAT --to-destination 10.0.0.4:3389 
iptables -A FORWARD -m udp -p udp --dport 2302:2502 -j ACCEPT
iptables -A FORWARD -m udp -p udp --sport 2302:2502 -j ACCEPT
# iptables -A FORWARD -m set --match-set MDNS src -m tcp -p tcp --dport 3389 -j ACCEPT
# iptables -A FORWARD -m set --match-set MDNS dst -m tcp -p tcp --sport 3389 -j ACCEPT
iptables -A FORWARD -j DROP
iptables -A INPUT -i eth0 -p udp --dport 51820 -j ACCEPT
iptables -A INPUT -i eth0 -m set --match-set MDNS src -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i eth0 -j DROP
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
