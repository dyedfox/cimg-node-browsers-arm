# vim:set ft=dockerfile:
# Multi-stage Dockerfile combining base, node, and browsers variants

# Stage 1: Base CircleCI image
FROM ubuntu:22.04 AS cimg-base

LABEL maintainer="CircleCI Execution Team <eng-execution@circleci.com>"

# Change default shell for RUN from Dash to Bash
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=dumb \
    PAGER=cat

# Configure environment
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci && \
	echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci && \
	apt-get update && apt-get install -y \
		curl \
		locales \
		sudo \
	&& \
	locale-gen en_US.UTF-8 && \
	rm -rf /var/lib/apt/lists/* && \
	\
	groupadd --gid=1002 circleci && \
	useradd --uid=1001 --gid=circleci --create-home circleci && \
	echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci && \
	echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep && \
	sudo -u circleci mkdir /home/circleci/project && \
	sudo -u circleci mkdir /home/circleci/bin && \
	sudo -u circleci mkdir -p /home/circleci/.local/bin && \
	\
	dockerizeArch=arm64 && \
	if uname -p | grep "x86_64"; then \
		dockerizeArch=x86_64; \
	fi && \
	curl -sSL --fail --retry 3 --output /usr/local/bin/dockerize "https://github.com/powerman/dockerize/releases/download/v0.8.0/dockerize-linux-${dockerizeArch}" && \
	chmod +x /usr/local/bin/dockerize && \
	dockerize --version

ENV PATH=/home/circleci/bin:/home/circleci/.local/bin:$PATH \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US:en \
	LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
		autoconf \
		build-essential \
		ca-certificates \
		cmake \
		# already installed but here for consistency
		curl \
		file \
		gettext-base \
		gnupg \
		gzip \
		jq \
		libcurl4-openssl-dev \
		libmagic-dev \
		# popular DB lib - MariaDB
		libmariadb-dev \
		# allows MySQL users to use MariaDB lib
		libmariadb-dev-compat \
		# popular DB lib - PostgreSQL
		libpq-dev \
		libssl-dev \
		libsqlite3-dev \
		lsof \
		make \
		# for ssh-enabled builds
		nano \
		net-tools \
		netcat-openbsd \
		openssh-client \
		parallel \
		# compiling tool
		pkg-config \
		postgresql-client \
		python-is-python3 \
		retry \
		shellcheck \
		software-properties-common \
		# already installed but here for consistency
		sudo \
		tar \
		tzdata \
		unzip \
		# for ssh-enabled builds
		vim \
		wget \
		zip && \
	# get the semi-official latest-stable git instead of using the old(er) version from the ubuntu distro
	add-apt-repository ppa:git-core/ppa && apt-get install -y git && \
	# get the semi-official latest-stable git-lfs too
	curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && apt-get install -y git-lfs && \
	# Quick test of the git & git-lfs install
	git version && git lfs version && \
	# Smoke test for python aliasing
	python --version && \
	rm -rf /var/lib/apt/lists/*

# Install Docker - needs the setup_remote_docker CircleCI step to work
ENV DOCKER_VERSION=5:28.1.1-1~ubuntu
RUN apt-get update && apt-get install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg-agent \
		software-properties-common && \
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
	add-apt-repository -y "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $( lsb_release -cs ) stable" && \
	apt-get install -y docker-ce=${DOCKER_VERSION}.$( lsb_release -rs )~$( lsb_release -cs ) docker-ce-cli=${DOCKER_VERSION}.$( lsb_release -rs )~$( lsb_release -cs ) containerd.io && \
	# Quick test of the Docker install
	docker --version && \
	rm -rf /var/lib/apt/lists/*

# Install Docker Compose - see prerequisite above
ENV COMPOSE_VER=2.27.1
ENV COMPOSE_SWITCH_VERSION=1.0.5
RUN dockerPluginDir=/usr/local/lib/docker/cli-plugins && \
	mkdir -p $dockerPluginDir && \
	curl -sSL "https://github.com/docker/compose/releases/download/v${COMPOSE_VER}/docker-compose-linux-$(uname -m)" -o $dockerPluginDir/docker-compose && \
	chmod +x $dockerPluginDir/docker-compose && \
	curl -fL "https://github.com/docker/compose-switch/releases/download/v${COMPOSE_SWITCH_VERSION}/docker-compose-linux-$(dpkg --print-architecture)" -o /usr/local/bin/compose-switch && \
	# Quick test of the Docker Compose install
	docker compose version && \
	chmod +x /usr/local/bin/compose-switch && \
	update-alternatives --install /usr/local/bin/docker-compose docker-compose /usr/local/bin/compose-switch 99 && \
	# Tests if docker-compose for v1 is transposed to v2
	docker-compose version

RUN YQ_ARCH=$(dpkg --print-architecture) && \
	curl -sSL "https://github.com/mikefarah/yq/releases/download/v4.42.1/yq_linux_$YQ_ARCH.tar.gz" | \
	tar -xz -C /usr/local/bin && \
	mv /usr/local/bin/yq{_linux_$YQ_ARCH,}

USER circleci
# Run commands and tests as circleci user
RUN whoami && \
	# opt-out of the new security feature, not needed in a CI environment
	git config --global --add safe.directory '*'

# Match the default CircleCI working directory
WORKDIR /home/circleci/project

# Stage 2: Add Node.js to the base image
FROM cimg-base AS cimg-node

USER root

LABEL maintainer="Community & Partner Engineering Team <community-partner@circleci.com>"

ENV NODE_VERSION=14.20.1
RUN curl -L -o node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-arm64.tar.xz" && \
	tar -xJf node.tar.xz -C /usr/local --strip-components=1 && \
	rm node.tar.xz && \
	ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV PATH=/home/circleci/.yarn/bin:$PATH
ENV YARN_VERSION=1.22.18
RUN curl -L -o yarn.tar.gz "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" && \
	tar -xzf yarn.tar.gz -C /opt/ && \
	rm yarn.tar.gz && \
	ln -s /opt/yarn-v${YARN_VERSION}/bin/yarn /usr/local/bin/yarn && \
	ln -s /opt/yarn-v${YARN_VERSION}/bin/yarnpkg /usr/local/bin/yarnpkg

# Install an alternative, but growing in popularity Node.js package manager
RUN npm install -g pnpm

# USER circleci
# WORKDIR /home/circleci/project

# Stage 3: Final image with browsers support
FROM cimg-node AS cimg-browsers

LABEL maintainer="CircleCI Community & Partner Engineering Team <community-partner@circleci.com>"

# Install Selenium
ENV SELENIUM_VER=3.141.59
RUN curl -sSL -o selenium-server-standalone-${SELENIUM_VER}.jar "https://selenium-release.storage.googleapis.com/${SELENIUM_VER%.*}/selenium-server-standalone-${SELENIUM_VER}.jar" && \
	sudo cp selenium-server-standalone-${SELENIUM_VER}.jar /usr/local/bin/selenium.jar && \
	rm selenium-server-standalone-${SELENIUM_VER}.jar

RUN sudo apt-get update && \
	# Install Java only if it's not already available
	# Java is installed for Selenium
	if ! command -v java > /dev/null; then \
		echo "Java not found in parent image, installing..." && \
		sudo apt-get install -y --no-install-recommends --no-upgrade openjdk-11-jre; \
	fi && \
	# Firefox deps
	sudo apt-get install -y --no-install-recommends --no-upgrade \
		libdbus-glib-1-2 \
		libgtk-3-dev \
		libxt6 \
	&& \
	# Google Chrome deps
	# Some of these packages should be pulled into their own section
	sudo apt-get install -y --no-install-recommends --no-upgrade \
		fonts-liberation \
		libappindicator3-1 \
		libasound2 \
		libatk-bridge2.0-0 \
		libatspi2.0-0 \
		libcairo2 \
		libcups2 \
		libgbm1 \
		libgdk-pixbuf2.0-0 \
		libgtk-3-0 \
		libpango-1.0-0 \
		libpangocairo-1.0-0 \
		libxcursor1 \
		libxss1 \
		xdg-utils \
		xvfb \
	&& \
	sudo rm -rf /var/lib/apt/lists/*

# Below is setup to allow xvfb to start when the container starts up.
# The label in particular allows this image to override what CircleCI does
# when booting the image.
LABEL com.circleci.preserve-entrypoint=true
ENV DISPLAY=":99"

RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' | sudo tee /docker-entrypoint.sh && \
	sudo chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/sh"]