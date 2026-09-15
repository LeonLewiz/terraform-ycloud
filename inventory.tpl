[managed]
%{ for k, v in vms ~}
${k} ansible_host=${v.network_interface[0].nat_ip_address} ansible_user=ubuntu ansible_ssh_private_key_file=${ssh_key_path}
%{ endfor ~}
