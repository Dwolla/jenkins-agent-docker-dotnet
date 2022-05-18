FROM eclipse-temurin:11.0.14.1_1-jre
MAINTAINER Dwolla Dev <dev+jenkins-dotnet@dwolla.com>
LABEL org.label-schema.vcs-url="https://github.com/Dwolla/jenkins-agent-docker-dotnet"
ARG TARGETPLATFORM


ENV JENKINS_HOME=/home/jenkins \
    JENKINS_AGENT=/usr/share/jenkins \
    AGENT_VERSION=2.61

COPY jenkins-agent /usr/local/bin/jenkins-agent

RUN apt-get update && apt-get install -y --no-install-recommends git
ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1

### Start .NET, from https://github.com/dotnet/dotnet-docker/blob/master/2.0/sdk/stretch/amd64/Dockerfile
# Install .NET CLI dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu66 \
        libssl1.1 \
        libstdc++6 \
        libunwind8 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ] ; then \
        DOTNET_SDK_VERSION=3.1.419; \
        DOTNET_SDK_DOWNLOAD_URL=https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-arm64.tar.gz; \
        DOTNET_SDK_DOWNLOAD_SHA='94f398c09b53c10dc3e4ed1f624eee19b18770734956ebb0cb4ac9d789c1a79a891c1934e7c4c3a2bed5326ee1a0417ee89816695ab2436b3db7076328a40b77'; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ] ; then \
        DOTNET_SDK_VERSION=2.0.0; \
        DOTNET_SDK_DOWNLOAD_URL=https://dotnetcli.blob.core.windows.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz; \
        DOTNET_SDK_DOWNLOAD_SHA='E457F3A5685382F7F24851A2E76EDBE75B575948C8A7F43220F159BA29C329A5008BBE7220C18DFB31EAF0398FC72177B1948B65E19B34ED0D907EFB459CF4B0'; \
    else \
        echo "invalid target platform ${TARGETPLATFORM} - must be linux/arm64 or linux/amd64" \
        && exit 99; \
    fi \    
    && curl -SL $DOTNET_SDK_DOWNLOAD_URL --output dotnet.tar.gz \
    && echo "$DOTNET_SDK_DOWNLOAD_SHA dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -zxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Trigger the population of the local package cache
ENV NUGET_XMLDOC_MODE skip
RUN mkdir warmup \
    && cd warmup \
    && dotnet new \
    && cd .. \
    && rm -rf warmup \
    && rm -rf /tmp/NuGetScratch
### END .NET

RUN curl --create-dirs -sSLo ${JENKINS_AGENT}/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar && \
    chmod 755 ${JENKINS_AGENT} && \
    chmod 644 ${JENKINS_AGENT}/agent.jar && \
    mkdir -p ${JENKINS_HOME} && \
    useradd --home ${JENKINS_HOME} --system jenkins && \
    chown -R jenkins ${JENKINS_HOME} && \
    chmod 755 /usr/local/bin/jenkins-agent && \
    apt-get clean

WORKDIR ${JENKINS_HOME}
USER jenkins

RUN git config --global user.email "dev+jenkins@dwolla.com" && \
    git config --global user.name "Jenkins Build Agent"

ENTRYPOINT ["jenkins-agent"]
