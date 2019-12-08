apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${ca_cert}
    server: https://127.0.0.1:6443
  name: ${project_name}
contexts: []
current-context: ""
kind: Config
preferences: {}
users:
- name: ${component}
  user:
    client-certificate-data: ${client_cert}
    client-key-data: ${client_key}
