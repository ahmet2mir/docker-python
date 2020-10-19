REGISTRY ?= quay.io

py36:
	docker build -t ${REGISTRY}/ahmet2mir/python:3.6 --build-arg PYTHON_PIP_VERSION=20.2.4 --build-arg PYTHON_VERSION=3.6.9 .
	docker push ${REGISTRY}/ahmet2mir/python:3.6

py37:
	docker build -t ${REGISTRY}/ahmet2mir/python:3.7 --build-arg PYTHON_PIP_VERSION=20.2.4 --build-arg PYTHON_VERSION=3.7.9 .
	docker push ${REGISTRY}/ahmet2mir/python:3.7

py38:
	docker build -t ${REGISTRY}/ahmet2mir/python:3.8 --build-arg PYTHON_PIP_VERSION=20.2.4 --build-arg PYTHON_VERSION=3.8.6 .
	docker tag ${REGISTRY}/ahmet2mir/python:3.8 ${REGISTRY}/ahmet2mir/python:latest
	docker push ${REGISTRY}/ahmet2mir/python:3.8
	docker push ${REGISTRY}/ahmet2mir/python:latest
