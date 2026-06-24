from kubernetes import client, config, watch
#from RPi import GPIO
from time import sleep
import subprocess
def set_led(r: bool, g: bool, b: bool):
    p = subprocess.Popen(["gpioset", "-c", "gpiochip0", "23=" + str(int(r))])
    sleep(.1) #TODO: minimize sleep time
    p.terminate()
    p = subprocess.Popen(["gpioset", "-c", "gpiochip0", "24=" + str(int(g))])
    sleep(.1)
    p.terminate()
    p = subprocess.Popen(["gpioset", "-c", "gpiochip0", "25=" + str(int(b))])
    sleep(.1)
    p.terminate()

config.load_kube_config(config_file="/home/admin/.kube/config")
v1 = client.CoreV1Api()
w = watch.Watch()

node_suffixes = set(["r1","r2","r3","r4"]) #TODO: consider replacing with regex, get node count programmatically
cpu_intensive_nodes = set() #nodes using high cpu. used to control fan PWM
nr_nodes = set() #nodes with "Not Ready" status
set_led(False, True, False) #init LED green
for event in w.stream(v1.list_node):
    node = event["object"]
    #print('event type: ', event["type"])
    ## Adjust PWM according to node CPU usage
    kt = subprocess.run(["sudo", "kubectl", "top", "node"], capture_output=True) #kubectl top node
    kt_stdout = kt.stdout.decode('utf-8')
    highcpucount = len(cpu_intensive_nodes)
    for i in range(20,len(kt_stdout)): #TODO: consider optimizing
        if kt_stdout[i] != " ":
            print(kt_stdout[i-2:i])
        if kt_stdout[i-2:i] in node_suffixes: #find worker hostname suffix, then get cpu usage
            for j in range(i, len(kt_stdout)):
                if kt_stdout[j] == "%":
                    if int(kt_stdout[j-3:j]) > 50:
                        cpu_intensive_nodes.add((kt_stdout[i-2:i]))
                    else:
                        cpu_intensive_nodes.remove((kt_stdout[i-2:i]))
    if highcpucount != len(cpu_intensive_nodes): #update PWM duty cycle
        subprocess.run("echo " + str(10000+int(20000*(len(cpu_intensive_nodes)/len(node_suffixes)))) + " > /sys/class/pwm/pwmchip0/pwm2/duty_cycle", shell=True, check=True)

    ## Set RGB LED according to node status
    for condition in node.status.conditions:
        if condition.type == "Ready": #currently not looking at MemoryPressure, DiskPressure, etc
            if condition.status == "True":
                if node.metadata.name in nr_nodes:
                    nr_nodes.remove(node.metadata.name)
                    if len(nr_nodes) == 0: #all nodes ready, set led green
                        set_led(False, True, False)
                    #node_status[node.metadata.name] = True
            else: #node is not ready
                nr_nodes.add(node.metadata.name)
                #node_status[node.metadata.name] = False
                if len(nr_nodes) == len(node_suffixes): #all 4 nodes down, set led red
                    set_led(True, False, False)
                else: #not all nodes down, set led blue
                    set_led(False, False, True)
        #print(node.metadata.name, " : ", condition.type, " : ", condition.status)