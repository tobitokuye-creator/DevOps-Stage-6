[app_servers]
app_server ansible_host=${server_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${private_key} ansible_ssh_common_args='-o StrictHostKeyChecking=no'
