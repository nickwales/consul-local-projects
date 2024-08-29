acl {
  enabled = true
  default_policy = "deny"
}
bind_addr = "{{ GetDefaultInterfaces | exclude \"type\" \"IPv6\" | attr \"address\" }}"
bootstrap_expect = 1
client_addr = "0.0.0.0"
data_dir = "./consul/"
log_level = "INFO"
server = true
ui = true