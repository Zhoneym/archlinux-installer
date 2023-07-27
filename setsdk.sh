#!/bin/bash


echo "export ANDROID_HOME=/home/arch/Android/Sdk/" >> /etc/profile
echo "export PATH=\$ANDROID_HOME/tools:\$PATH" >> /etc/profile
echo "export PATH=\$ANDROID_HOME/platform-tools:\$PATH" >> /etc/profile

source /etc/profile
