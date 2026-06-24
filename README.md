# Project Setup Guide

This guide outlines the procedures for setting up an airgapped Kubernetes (k3s) cluster on Raspberry Pi 5 machines.

## Notes on deployment design and potential improvements
 The current deployment process uses SSH/SCP-based scripts to bootstrap Raspberry Pi nodes. For a larger deployment or a redo of this project, I would consider writing a custom RPi OS imager and migrating the project to a configuration management tool such as Ansible to streamline automation. Headless setup with a tool like Ansible (full automation) is currently difficult due to various bugs ([1](https://github.com/raspberrypi/rpi-imager/issues/1380), [2](https://github.com/raspberrypi/rpi-imager/issues/1519)) in the RPi imager.

## Setup steps
1. Flash RPi OS Lite onto the boot storage drives, making sure that all hostnames are unique and all usernames are the same. Add your ssh key, and enable automatic login. Connect all RPis to a router with a DHCP server if available (not required), either through ethernet or wifi. If headless setup does not work due to RPi imager bug(s), you will have to set up each machine manually.
2. SSH into every RPi with ssh username@hostname.local (mDNS) if you had a DHCP server in step 1 and disable the sudo password requirement on all the machines for your user. While doing this, set static IPs for eth0 (see ./utils/set_static_ip.sh for the necessary commands). If you did not have a DHCP server, you will need to complete this step by plugging a keyboard and monitor into each RPi. Note that the batch install scripts hardcode the IPs in a `192.168.50.1,2,3,...` configuration with bitmask `255.255.255.0`, so if you wish to use a different IP configuration you may need to modify the install scripts.
3. Run the batch_preinstall script. The RPis should reboot.
4. Run the batch_install script. The RPi with assigned IP `192.168.50.1` will be setup as the control plane, and the rest will be worker nodes.

## File Descriptions
```
📂 k3s_airgapped_cluster/
├── README.md        
├── batch_install.sh             # Installs k3s on all machines over SSH, executed from workstation
├── batch_preinstall.sh          # Completes preinstall requirements on all machines over SCP/SSH, executed from workstation
│
├── resources/                   # Files necessary for airgapped install of k3s
│   ├── k3s-airgap-images-arm64.tar                     
│   └── k3s-arm64                
│
├── server_scripts/              
│   └── tools/                   
│       ├── perf_monitor.py      # Python script for PWM cooling and RGB LED (GPIO) control, to be run on RPis as a background service
│       ├── perf-monitor.service # Service for perf-monitor.sh
│       ├── perf-monitor.sh      # Script that runs perf_monitor.py in a venv
│       ├── pwm-init.service     # Service for pwm-init.sh
│       └── pwm-init.sh          # Script that needs to run on startup on RPis to enable hardware PWM
│   ├── install.sh               # Install script for k3s, executed on RPis
│   ├── k3s-route-setup.sh       # Script that needs to run on startup on RPis so that k3s has a default ip route
│   └── preinstall.sh            # Preinstall script, executed on RPis
│
└── utils/                       
    ├── set_static_ip.sh         # Sets static ip for eth0 port on RPis over SSH using mDNS, executed on RPis
    ├── sync_time.sh             # Syncs time on all RPis to avoid TLS issues in airgapped install
    └── transfer.sh              # Transfers necessary files to RPis over SCP
```

## Appendix: Monitoring scripts and hardware PWM

### Python k8s Library Installation (Airgapped)

Download the k8s source distribution from pypi and download all the required .whl files into a folder in that source with `pip download -r requirements.txt -d ./local_wheels`  (see requirements.txt in the top folder of the source distro).
Be warned that if you are using an OS or have a python distro that requires a different binary than your RPi for certain dependencies, you may have to download those manually. The `pyyaml` and `charset_normalizer` packages are likely culprits. Finally, in the source folder run `sudo pip install --no-index --find-links ./local_wheels -r requirements.txt`. You may need to run this with a python venv.

### GPIO PWM Control on RPi 5

Pulse Width Modulation (PWM) of GPIO pins is a little tricky on RPi 5 compared to RPi 4/3. To my knowledge there is no CLI tool or default library included with rpiOS that can be used to control it. Furthermore, the search results for third party libraries is very sparse. That being said, hardware PWM can be configured with the linux sysfs PWM interface, and there is some documentation [here](https://docs.kernel.org/driver-api/pwm.html#using-pwms-with-the-sysfs-interface). 

The below steps are a result of working through this [writeup](https://github.com/seamusdemora/PiFormulae/blob/master/PWM-onRPi_5.md):
1. Add dtoverlay=pwm to /boot/firmware/config.txt, then reboot
2. Look in /sys/class/pwm folder- notice the only folder is pwmchip0. (If you see other folders, you may need to investigate to see which folders control which GPIO pins.)
3. Call pinctrl | grep PWM- notice GPIO18 is listed with PWM0_CHAN2
4. cd to pwmchip0 and export channel 2: echo 2 > export
5. Notice that a new folder pwm2 was created in pwmchip0
6. cd to pwm2 (path /sys/class/pwm/pwmchip0/pwm2) and set the pwm parameters as below:
7. echo 40000 > period (25khz for many PC fans)
8. echo 20000 > duty_cycle (set as desired)
9. echo 1 > enable
10. Test the PWM output with an oscilloscope, or simply connect the desired device.