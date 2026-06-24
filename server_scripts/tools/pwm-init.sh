#!/bin/bash
echo 2 > /sys/class/pwm/pwmchip0/export
sleep 1
echo 40000 > /sys/class/pwm/pwmchip0/pwm2/period
echo 10000 > /sys/class/pwm/pwmchip0/pwm2/duty_cycle
echo 1 > /sys/class/pwm/pwmchip0/pwm2/enable