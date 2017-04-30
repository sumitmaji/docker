FROM ubuntu:latest
MAINTAINER Sumit Kumar Maji

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -yq openssh-client
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# passwordless ssh
RUN ssh-keygen -qy -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -qy -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN mkdir /root/.ssh
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN addgroup hadoop
RUN adduser --ingroup hadoop hduser
RUN adduser hduser sudo

RUN su - hduser -c "ssh-keygen -t rsa -P \"\" -f /home/hduser/.ssh/id_rsa"
RUN su - hduser -c "cp /home/hduser/.ssh/id_rsa.pub /home/hduser/.ssh/authorized_keys"

ADD ssh_config /home/hduser/.ssh/config
RUN chmod 600 /home/hduser/.ssh/config
RUN chown hduser:hadoop /home/hduser/.ssh/config



RUN echo 'hduser:hadoop' | chpasswd


EXPOSE 22 2122
CMD ["/usr/sbin/sshd", "-D"]
