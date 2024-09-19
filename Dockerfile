FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# apt-get update
RUN apt-get update

# Set locales
# https://hub.docker.com/_/ubuntu
RUN apt-get install -y locales && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install tools
RUN apt-get install -y wget tar unzip zip curl git sudo gnupg sqlite3 tzdata

# https://github.com/aoudiamoncef/ubuntu-sshd
ENV SSH_USERNAME=ubuntu
ENV PASSWORD=ubuntu

# Install OpenSSH server
RUN apt-get update \
    && apt-get install -y openssh-server iputils-ping telnet iproute2

# Create the privilege separation directory and fix permissions
RUN mkdir -p /run/sshd \
    && chmod 755 /run/sshd

# Check if the user exists before trying to create it
RUN if ! id -u $SSH_USERNAME > /dev/null 2>&1; then useradd -ms /bin/bash $SSH_USERNAME; fi

# Set up SSH configuration
RUN mkdir -p /home/$SSH_USERNAME/.ssh && chown $SSH_USERNAME:$SSH_USERNAME /home/$SSH_USERNAME/.ssh \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copy the script to configure the user's password and authorized keys
COPY configure-ssh-user.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/configure-ssh-user.sh

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose SSH port
# EXPOSE 22

# Start SSH server
CMD ["/usr/local/bin/configure-ssh-user.sh"]
