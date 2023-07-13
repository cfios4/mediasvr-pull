FROM linuxserver/code-server:latest
ARG DOCKER_GID

COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/
RUN groupadd -g $DOCKER_GID docker && \ 
   usermod -aG docker abc && \
   touch /var/run/docker.sock && \
   chown :docker /var/run/docker.sock

RUN printf "alias 'terraform'='docker run --rm -v $PWD:/workspace -w /workspace -it hashicorp/terraform'\nalias 'packer'='docker run --rm -v $PWD:/workspace -w /workspace -it hashicorp/packer'" >> /etc/bash.bashrc


#docker build --build-arg DOCKER_GID=$(cut -d: -f3 < <(getent group docker)) .
