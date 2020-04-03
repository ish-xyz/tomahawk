resource "helm_release" "network_pod" {
  name      = "flanel"
  chart     = "helm-charts/flannel"
  namespace = "kube-system"
}


resource "null_resource" "netowork_setup" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  triggers = {
    "before" = "${helm_release.network_pod.id}"
  }
}