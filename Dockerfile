FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Aisa/Singapore

RUN apt-get update && apt-get install apache2-utils iproute2 ansible ssh vim python3 sshpass python3-pip -y &&\
pip3 install flask &&\
pip3 install passlib 

COPY . /root/ansible

RUN sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config &&\
sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config &&\
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config &&\
sed -i "s/#host_key_checking = False/host_key_checking = False/" /etc/ansible/ansible.cfg &&\
sed -i "s/#forks          = 5/forks          = 1/" /etc/ansible/ansible.cfg &&\
mkdir -p /run/sshd &&\
chmod +x /root/ansible/*.sh


ENTRYPOINT ["/usr/sbin/sshd","-D"]


