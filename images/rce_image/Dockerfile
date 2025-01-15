FROM python:3.14.0a3-slim-bookworm

MAINTAINER Matt Jarvis "matt.jarvis@snyk.io"

RUN apt-get update && apt-get install -y curl \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -u 999 -G sudo -ms /bin/bash webadmin

USER webadmin:webadmin

COPY requirements.txt ./
RUN pip install --user --no-cache-dir -r requirements.txt

WORKDIR /usr/src/app
RUN chown webadmin /usr/src/app -R

COPY . .

ENTRYPOINT [ "python" ]

CMD [ "app.py" ]
