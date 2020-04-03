resource "helm_release" "dns_pod" {

  depends_on = [
    null_resource.netowork_setup
  ]

  name      = "coredns"
  chart     = "helm-charts/coredns"
  namespace = "kube-system"

}
