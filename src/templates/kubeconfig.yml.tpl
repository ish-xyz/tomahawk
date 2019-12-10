apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${ca_cert}
    server: https://127.0.0.1:6443
  name: ${project_name}
contexts:
- context:
    cluster: ${project_name}
    user: ${user}
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: ${user}
  user:
    client-certificate-data: ${client_cert}
    client-key-data: ${client_key}
