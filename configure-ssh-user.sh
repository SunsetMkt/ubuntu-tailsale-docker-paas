#!/bin/bash
# https://github.com/aoudiamoncef/ubuntu-sshd

# Set default values for SSH_USERNAME and PASSWORD if not provided
: ${SSH_USERNAME:=ubuntu}
: ${PASSWORD:=ubuntu}

# Create the user with the provided username and set the password
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists"
else
    useradd -ms /bin/bash "$SSH_USERNAME"
    echo "$SSH_USERNAME:$PASSWORD" | chpasswd
    echo "User $SSH_USERNAME created with the provided password"
fi

# Set the authorized keys from the AUTHORIZED_KEYS environment variable (if provided)
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p /home/$SSH_USERNAME/.ssh
    echo "$AUTHORIZED_KEYS" > /home/$SSH_USERNAME/.ssh/authorized_keys
    chown -R $SSH_USERNAME:$SSH_USERNAME /home/$SSH_USERNAME/.ssh
    chmod 700 /home/$SSH_USERNAME/.ssh
    chmod 600 /home/$SSH_USERNAME/.ssh/authorized_keys
    echo "Authorized keys set for user $SSH_USERNAME"
fi

# Setup Tailscale
# https://tailscale.com/kb/1132/flydotio
# tailscale status --peers=false --json | grep -q 'Online.*true' # https://github.com/tailscale/tailscale/issues/12758
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
tailscale up --authkey=${TS_AUTHKEY} --hostname=${TS_HOSTNAME} --advertise-exit-node=true --ssh=true --webclient=true --accept-dns --advertise-tags=tag:ci

# Start the SSH server
exec /usr/sbin/sshd -D