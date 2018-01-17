#####################################
# 2018 ithome ironman
# Author: James Lu
# Topic: k8s 不自賞 - Day 30 鐵人達成
# Url: https://ithelp.ithome.com.tw/articles/10197352
# Licence: MIT
#####################################
FROM golang
WORKDIR /go/src/app

COPY ./go .

RUN go get gopkg.in/mgo.v2
RUN go build -o app

ENTRYPOINT ./app
