output "data" {
  sensitive = false
  value = {
    ip             = module.redis.result.instances,
    # replicas-ip    = module.redis.result.replicas
  }
}