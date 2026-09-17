# Generates the kind (Kubernetes in Docker) cluster configuration.
resource "local_file" "kind_config" {
  filename = var.config_path
  content  = <<-KIND
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: ${var.cluster_name}
    nodes:
      - role: control-plane
        extraPortMappings:
          - containerPort: 30080
            hostPort: 8080
            protocol: TCP
  KIND
}
