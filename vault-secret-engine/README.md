# Instructions

### Start a Consul server

```
consul agent -config-file ./consul.hcl
```


### Start a Vault server

```
vault server -dev -dev-root-token-id="root"
```

### In a new tab configure Vault with a Consul secrets engine
```
vault secrets enable consul
vault write consul/config/access \
    address="127.0.0.1:8500" \
    bootstrap=true
```

#### Create a global management token role because the existing one is hidden in Vault

```
vault write consul/roles/consul-server-root-policy \
    consul_policies="global-management"
```

#### Create a role with node policies and a policy to use it
```
vault write consul/roles/consul-server-agent-role \
    node_identities="server001:dc1", \
    node_identities="server002:dc1", \
    node_identities="server003:dc1"

vault policy write consul-server-agent-role ./consul-server-agent-role.hcl
```
  We cannot know cloud instance names in advance, this is a problem.



#### Login as a "consul server"
```
$ export VAULT_TOKEN=$(vault token create -policy=consul-server-agent-role -format=json | jq -r '.auth.client_token')
$ vault read consul/creds/consul-server-agent-role

Key                 Value
---                 -----
lease_id            consul/creds/consul-server-agent-role/PJt8cu2Re8Hc1rRO3ZiTKyXa
lease_duration      768h
lease_renewable     true
accessor            52361422-69be-25ea-51cf-664e012fd5cc
consul_namespace    n/a
local               false
partition           n/a
token               216338df-9710-7fef-d249-848d8187e8c2
```

If we take a look at that token, it has ALL of the associated node identites.
```
$ consul acl token read -accessor-id=52361422-69be-25ea-51cf-664e012fd5cc
AccessorID:       52361422-69be-25ea-51cf-664e012fd5cc
SecretID:         216338df-9710-7fef-d249-848d8187e8c2
Description:      Vault consul-server-agent-role token 1724960832611526000
Local:            false
Create Time:      2024-08-29 14:47:12.612675 -0500 CDT
Node Identities:
   server001 (Datacenter: dc1,)
   server002 (Datacenter: dc1,)
   server003 (Datacenter: dc1)
```   

Having multiple identities per token doesn't seem ideal, we can't choose one of the identities from the command afaict.

It we were to do it this way, somehow as Consul servers come up we'd need to create a new role for each instance.

Servers would somehow have to update vault with a Vault role specifically for them as they come up.
