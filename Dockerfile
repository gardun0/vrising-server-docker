#########  RUNNER  ##########

FROM scottyhardy/docker-wine:stable-7.0

LABEL maintainer="hola@jrge.dev"

#########  STEAMCMD  ##########

ARG PUID=1000

ENV USER steam
ENV HOMEDIR "/home/${USER}"
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"

RUN set -x \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
                lib32stdc++6 \
                lib32gcc-s1 \
                wget \
                ca-certificates \
                nano \
                curl \
                locales \
	&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& dpkg-reconfigure --frontend=noninteractive locales \
	# Create unprivileged user
	&& useradd -u "${PUID}" -m "${USER}" \
	# Download SteamCMD, execute as user
	&& su "${USER}" -c \
		"mkdir -p \"${STEAMCMDDIR}\" \
		&& wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
		&& \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
		&& mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
		&& ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
		&& ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
	# Symlink steamclient.so; So misconfigured dedicated servers can find it
	&& ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" \
	# Clean up
        && apt-get remove --purge --auto-remove -y \
                wget

WORKDIR ${STEAMCMDDIR}

######### END STEAMCMD  ##########

######### FETCHING  ##########

ENV STEAMAPPID 1829350
ENV STEAMAPP vrising
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"

COPY "etc/**" "${HOMEDIR}"

RUN set -x \
	# Install, update & upgrade packages
  && mkdir -p "${STEAMAPPDIR}" \
	&& chmod 755 "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" "${HOMEDIR}/run.sh" \
	&& chown "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/run.sh" "${STEAMAPPDIR}" \
  # Clean up
	&& rm -rf /var/lib/apt/lists/*

RUN ${HOMEDIR}/entry.sh

######### END FETCHING  ##########

WORKDIR ${STEAMAPPDIR}

RUN winetricks -q npp

ENTRYPOINT ${HOMEDIR}/run.sh