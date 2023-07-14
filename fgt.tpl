Content-Type: multipart/mixed; boundary="===============0086047718136476635=="
MIME-Version: 1.0

--===============0086047718136476635==
config system global
    set admin-sport 7443
    set admintimeout 480
    set hostname ${fgt_id}
end

config system interface
    edit port1
        set mode dhcp
        set dhcp-classless-route-addition enable
    next
    edit port2
        set mode dhcp
        set dhcp-classless-route-addition enable
    next
    edit port3
        set mode dhcp
        set dhcp-classless-route-addition enable
    next
end

config user local
    edit student
        set type password
        set passwd FortiDeceptor123$
    next
end

config user group
    edit SSL-Group
        set member student
    next
end

config vpn ssl settings
    set port 10443
    set servercert Fortinet_Factory
    set tunnel-ip-pools SSLVPN_TUNNEL_ADDR1
    set tunnel-ipv6-pools SSLVPN_TUNNEL_IPv6_ADDR1
    set source-interface port1
    set source-address all
    set source-address6 all
    set default-portal web-access
    config authentication-rule
        edit 1
            set groups SSL-Group
            set portal full-access
        next
    end
end

config firewall address
    edit trust_sub
        set subnet 192.168.1.0 255.255.255.0
    next
    edit tools_sub
        set subnet 10.0.1.0 255.255.255.0
    next
end

config firewall addrgrp
    edit internal
    set member trust_sub tools_sub
    next
end

config firewall policy
    edit 0
        set name trust-out
        set srcintf port2
        set dstintf port1
        set action accept
        set srcaddr trust_sub
        set dstaddr all
        set schedule always
        set service ALL
        set nat enable
    next
    edit 0
        set name tools-out
        set srcintf port3
        set dstintf port1
        set action accept
        set srcaddr tools_sub
        set dstaddr all
        set schedule always
        set service ALL
        set nat enable
    next
    edit 2
        set name ssl-in
        set srcintf ssl.root
        set dstintf port2 port3
        set action accept
        set srcaddr SSLVPN_TUNNEL_ADDR1
        set dstaddr internal
        set schedule always
        set service ALL
        set nat enable
        set groups SSL-Group
    next
end

--===============0086047718136476635==
