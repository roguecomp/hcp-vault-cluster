# allow aws login
path "auth/aws/login" {
    capabilities = ["update"]
}

# allow kv read
path "kv/data/up-bank/access-token" {
    capabilities = ["read"]
}