FROM python:3.13-slim

ENV PYTHONBUFFERED=1

WORKDIR /project_dir
COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt


EXPOSE 8000
