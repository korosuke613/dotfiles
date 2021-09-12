# lima settings

## setup

Add the following to `~/.ssh/config`
```
Host localhost
  HostName localhost
  User korosuke613
  NoHostAuthenticationForLocalhost yes
  Port 60006
```

## start
```
limactl start ~/dotfiles/lima/docker.yaml
```

