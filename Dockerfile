FROM openjdk:8-jre
MAINTAINER Dwolla Dev <dev+jenkins-dotnet@dwolla.com>
LABEL org.label-schema.vcs-url="https://github.com/Dwolla/jenkins-agent-docker-dotnet"

ENV JENKINS_HOME=/home/jenkins \
    JENKINS_AGENT=/usr/share/jenkins \
    AGENT_VERSION=2.61

COPY jenkins-agent /usr/local/bin/jenkins-agent
COPY verify.sh /usr/local/bin/verify.sh

RUN apt-get update && \
    apt-get install -y curl bash git ca-certificates python make g++ libunwind8 gettext && \
    curl --create-dirs -sSLo ${JENKINS_AGENT}/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar && \
    chmod 755 ${JENKINS_AGENT} && \
    chmod 644 ${JENKINS_AGENT}/agent.jar && \
    mkdir -p ${JENKINS_HOME} && \
    useradd --home ${JENKINS_HOME} --system jenkins && \
    chown -R jenkins ${JENKINS_HOME} && \
    chmod 755 /usr/local/bin/jenkins-agent && \
    apt-get clean

WORKDIR ${JENKINS_HOME}
USER jenkins

RUN curl -sSL -o dotnet.tar.gz https://go.microsoft.com/fwlink/?linkid=848826 \
    mkdir -p /opt/dotnet && tar zxf dotnet.tar.gz -C /opt/dotnet \
    ln -s /opt/dotnet/dotnet /usr/local/bin

RUN git config --global user.email "dev+jenkins@dwolla.com" && \
    git config --global user.name "Jenkins Build Agent"

ENTRYPOINT ["jenkins-agent"]