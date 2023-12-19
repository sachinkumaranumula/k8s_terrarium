# Additional OS login IAM bindings.
# https://cloud.google.com/compute/docs/instances/managing-instance-access#granting_os_login_iam_roles
resource "google_service_account" "k8s_sa" {
  project      = var.project
  account_id   = "k8s-cp"
  display_name = "Service Account for k8s Control Plane"
}

resource "google_service_account_iam_binding" "k8s_sa" {
  service_account_id = google_service_account.k8s_sa.name
  role               = "roles/iam.serviceAccountUser"
  members            = var.members
}

resource "google_project_iam_member" "os_login_bindings" {
  for_each = toset(var.members)
  project  = var.project
  role     = "roles/compute.osLogin"
  member   = each.key
}
