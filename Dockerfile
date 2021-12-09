FROM python:3.10-alpine

ENV FILENAME_FORMAT='{kind}-{group}-{version}'

WORKDIR /out/schemas

RUN wget -O /usr/local/bin/openapi2jsonschema https://raw.githubusercontent.com/yannh/kubeconform/v0.4.12/scripts/openapi2jsonschema.py \
 && chmod +x /usr/local/bin/openapi2jsonschema \
 && python3 -m pip install pyyaml

ENTRYPOINT ["/usr/local/bin/openapi2jsonschema"]
