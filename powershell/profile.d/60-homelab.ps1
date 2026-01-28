# Reloads the Caddyfile on SCARIF
function Invoke-CaddyfileReload {
    param (
        [Parameter(Position = 0)]
        [ValidateSet("caddy", "caddy-private")]
        [string]
        $ContainerName = "caddy"
    )
    & ssh root@scarif docker exec $ContainerName caddy reload --config /etc/caddy/Caddyfile
}
