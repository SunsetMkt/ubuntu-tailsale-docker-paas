FROM ubuntu:24.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# apt-get update
RUN apt-get update

# unminimize
# RUN unminimize # Not found

# Set locales
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LC_ALL en_US.UTF-8 
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en     

# Install tools
RUN apt-get install -y wget tar unzip zip curl git sudo gnupg sqlite3 tzdata ca-certificates iptables \
    software-properties-common apt-transport-https vim nano net-tools xvfb php npm supervisor build-essential \
    dotnet-sdk-8.0 default-jdk python3 python3-pip traceroute nmap tmux tmate
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Tailscale
# https://tailscale.com/kb/1107/heroku
# Copy Tailscale binaries from the tailscale image on Docker Hub.
# COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /usr/local/bin/tailscaled
# COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /usr/local/bin/tailscale
# RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

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
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

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
