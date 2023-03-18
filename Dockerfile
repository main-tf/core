#FROM minio/mc:RELEASE.2021-10-07T04-19-58Z as mc

FROM bitnami/kubectl:1.21.3 as kubectl

#FROM alpine/terragrunt:1.0.5 as terragrunt

#RUN apk -u add wget git unzip bash jq

#RUN apk -u add wget unzip

FROM hashicorp/terraform:1.0.7 as tf

#FROM busybox as dl

#RUN wget --no-check-certificate https://github.com/gruntwork-io/terragrunt/releases/download/v0.32.3/terragrunt_linux_amd64 -O /bin/terragrunt && \
#    chmod 0755 /bin/terragrunt

# RUN wget -nv https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip -O /tmp/terraform.zip && \
#    cd /tmp && unzip terraform.zip && mv terraform /usr/bin/ && rm terraform.zip

FROM python:3.10-slim

ENV PYTHONUNBUFFERED=1 \
    # prevents python creating .pyc files
    PYTHONDONTWRITEBYTECODE=1 \
    \
    # pip
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    \
    # poetry
    # https://python-poetry.org/docs/configuration/#using-environment-variables
    POETRY_HOME="/opt/poetry" \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1

#RUN sed -i 's/deb.debian.org/cdn-fastly.deb.debian.org/' /etc/apt/sources.list
#RUN rm -r /var/lib/apt/lists/*
RUN apt-get update 
# && apt -y upgrade 
RUN apt -y install ca-certificates
#COPY --from=mc /usr/bin/mc /usr/bin/mmc
COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /bin/
COPY bin/terragrunt /bin/
COPY --from=tf /bin/terraform /bin/

RUN pip install poetry
COPY pyproject.toml /src/state/      
COPY poetry.lock /src/state/
RUN cd /src/state; poetry install
#RUN mkdir -p /src/tf /src/kv
ADD . /src/state

# https://terragrunt.gruntwork.io/docs/reference/cli-options/
#padla bljad
#ENV TERRAGRUNT_DOWNLOAD=/run/tg

RUN cd /src/state && terraform init && terraform apply -auto-approve
WORKDIR /src/state/infra

ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV REFRESH_INVENTORY=1