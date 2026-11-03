Ubuntu VM CPU & RAM Utilization Testing

Simple commands to generate CPU and RAM utilization for monitoring and alert testing using stress-ng.

1. Install Package
bash
sudo apt update
sudo apt install stress-ng -y

2. CPU Utilization

Generate 80% CPU load for 5 minutes:

bash
stress-ng --cpu 0 --cpu-load 80 --timeout 5m


Monitor:

bash
top

3. RAM Utilization

Generate approximately 1 GB RAM load for 5 minutes:

bash
stress-ng --vm 1 --vm-bytes 1G --timeout 5m


Monitor:

bash
free -h

4. Cleanup
bash
pkill stress-ng


Note: Run only on test VMs. Ensure sufficient available RAM and CPU resources before testing. Adjust worker count and memory allocation according to VM capacity.