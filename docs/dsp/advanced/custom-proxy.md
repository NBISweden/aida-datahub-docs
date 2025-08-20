# Setting up a custom HTTP Proxy

By default, the Virtual Machines (VMs) on the Data Science Platform (DSP) can make HTTP requests to the outside world only by going through an inspecting proxy.
To make the default configuration of DSP secure, this proxy has a strict list of allowed resources that internal machines can access. For some projects, the default is too strict, and one way of getting around it is to set up your own proxy for your VMs.

But do note that before doing so you must verify that it follows the overall security guidelines for the current research project.

In this guide, we will set up a different proxy on a VM using `privoxy` and tunnel HTTP requests through the connecting machine´s SSH connection.

As a curiosity, this builds a lot on functionality offered by OpenSSH and the privoxy bits can in many cases be bypassed by referencing the SOCKS5 proxy OpenSSH provides directly, e.g. by `http_proxy=socsk5h://127.0.0.1:3128`. But while it has fairly wide support it's not universal, and adding privoxy to serve as a http proxy will help with some of those - but if you just need a quick apt install or similar, you can bypass that and use the socks proxy directly.

**Note that this will circumvent strict filtering and essentially allow any HTTP request from your VM to be carried out (unless you explicitly add filtering on your own machine or network).**

## Set up `privoxy` on the VM

`privoxy` is a simple web proxy which is provided in the base Ubuntu repositories, this means that it will be easy to install it on Ubuntu-based VMs on DSP since the default package repositories are in our allow lists. Install it on your VM by running:

```shell
sudo apt install privoxy
```
Now we need to configure it to forward requests using SOCKS5:

```shell
echo 'forward-socks5  /  127.0.0.1:3128  .' | sudo tee -a /etc/privoxy/config
```

Restart `privoxy` to read the changes:

```shell
sudo systemctl restart privoxy
```

Now disconnect from the VM (we need to add additional configurations to the SSH client)


```shell
exit
```

## Configure SSH

Above, we configured `privoxy` to forward HTTP requests to a SOCKS5 proxy on the port `3128` on the machine where it´s running (i.e. the VM). We'll now make our own connecting machine relaying the HTTP requests by telling our SSH client to listen to this port on the remote host (VM) and tunnel traffic to our connecting machine. We do this by using a "remote forward" connection. You can do this "on-the-fly" when you connect to your machine using the flag `-R 3128`, but it's more convenient to add this to your SSH config:

```
Host dsp-project
  HostName [VM_FLOATING_IP]
  User ubuntu
  ProxyJump dsp
  ServerAliveInterval 10
  RemoteForward 3128 localhost:3128

Host dsp
  Hostname dsp.aida.scilifelab.se
  User [MY_EMAIL]
```

The `RemoteForward 3128` is what sets up the reverse tunnel.

Now when you connect to your VM over SSH (e.g. `ssh dsp-project` in config example above), SSH will forward any traffic connecting to the port 3128 on the VM to our connecting machine and carry out the HTTP requests.

## Configure remote programs

By default, the VM is configured to use the DSP HTTP proxy. This is set up using the environmental variables `HTTP_PROXY`, `HTTPS_PROXY`, `http_proxy` and `https_proxy`. We'll replace their values with the address of our `privoxy` instance instead. By default it listens to port 8118 for requests, so we'll set our environmental variables to this:

```shell
export http_proxy=http://127.0.0.1:8118 https_proxy=http://127.0.0.1:8118
export HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118
```

This changes the variables for the currently running shell (so just for your current session). Once you have exported the variables, you should be able to test that the proxy works by running (in the same shell):

```shell
curl -v --proxy http://127.0.0.1:8118 https://example.com
```

Which should output an HTML document to you terminal; the HTMLlanding page of `example.com`.

### Creating alias for temporarily switching proxy

We can add a shell alias if we want to temporarily set the environmental variables:

```shell
alias proxy='http_proxy=http://127.0.0.1:8118 https_proxy=http://127.0.0.1:8118 HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118'
```

Then use it for specific commands:
```shell
proxy pip3 install numpy   # Uses proxy
pip3 install numpy         # Does not use proxy
```

### Making Proxy Settings Persistent

The above exports of environmental variables only affect the shell you run it in, and you might want your proxy to be used throughout your account. To achieve that run the following:

```shell
cat >> ~/.bashrc << EOF

# Proxy settings
export http_proxy=http://127.0.0.1:8118
export https_proxy=http://127.0.0.1:8118
export HTTP_PROXY=http://127.0.0.1:8118
export HTTPS_PROXY=http://127.0.0.1:8118
EOF
```

Then reload your bash configuration:
```shell
source ~/.bashrc
```

## Disabling Privoxy

To remove the persistent settings from your `.bashrc`:

```shell
sed -i \
    -e '/^# Proxy settings$/d' \
    -e '/^export http_proxy=http:\/\/127\.0\.0\.1:8118$/d' \
    -e '/^export https_proxy=http:\/\/127\.0\.0\.1:8118$/d' \
    -e '/^export HTTP_PROXY=http:\/\/127\.0\.0\.1:8118$/d' \
    -e '/^export HTTPS_PROXY=http:\/\/127\.0\.0\.1:8118$/d' \
    ~/.bashrc
```

To temporarily stop Privoxy:
```shell
sudo systemctl stop privoxy
```

To disable Privoxy from starting on boot:
```shell
sudo systemctl disable privoxy
```

To completely remove Privoxy:
```shell
sudo apt remove privoxy
sudo apt autoremove
```


### Configuring APT to Use Privoxy
While the default sources for APT are allowed in the DSP proxy, you might have added additional package repositories, in which case they will likely be blocked. You can tell APT to use privoxy instead by adding a proxy configuration file:

1. **Create an APT configuration file for the proxy:**
   ```shell
   sudo bash -c 'cat > /etc/apt/apt.conf.d/80proxy << EOF
   Acquire::http::Proxy "http://127.0.0.1:8118";
   Acquire::https::Proxy "http://127.0.0.1:8118";
   EOF'
   ```

2. **Verify the configuration:**
   ```shell
   cat /etc/apt/apt.conf.d/80proxy
   ```

3. **Test APT with the proxy:**
   ```shell
   sudo apt update
   ```

## Docker Proxy Configuration

### System-Wide Docker Proxy (Method 1)

1. Create or edit the Docker service configuration file:
   ```shell
   sudo mkdir -p /etc/systemd/system/docker.service.d/
   sudo bash -c 'cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
   [Service]
   Environment="HTTP_PROXY=http://127.0.0.1:8118"
   Environment="HTTPS_PROXY=http://127.0.0.1:8118"
   Environment="NO_PROXY=localhost,127.0.0.1,::1"
   Environment="no_proxy=localhost,127.0.0.1,::1"
   EOF'
   ```

2. Reload the Docker daemon configuration:
   ```shell
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

3. Verify the Docker proxy settings:
   ```shell
   sudo systemctl show --property=Environment docker
   ```

### Docker Client Configuration (Method 2)

For a user-specific Docker configuration:
```shell
mkdir -p ~/.docker
cat > ~/.docker/config.json << EOF
{
 "proxies":
 {
   "default":
   {
     "httpProxy": "http://127.0.0.1:8118",
     "httpsProxy": "http://127.0.0.1:8118",
     "noProxy": "localhost,127.0.0.1,::1"
   }
 }
}
EOF
```

### Docker Build and Run with Proxy

To make your proxy available during docker build:
```shell
docker build --network=host .
```

To run a container with host network (and thus access to your proxy):
```shell
docker run -it --rm --network host ubuntu bash
```

### Using Proxy Inside Docker Container

Inside the container, set up proxy configuration the 
same way as we've done above in this guide:

```shell
# Create an alias for temporary proxy usage
alias proxy='http_proxy=http://127.0.0.1:8118 https_proxy=http://127.0.0.1:8118 HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118'

# Use proxy for specific commands
proxy pip3 install numpy   # Uses proxy
pip3 install numpy         # Does not use proxy

# Or set for the entire session
export http_proxy=http://127.0.0.1:8118 https_proxy=http://127.0.0.1:8118
export HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118
pip3 install numpy         # Now uses proxy
```
