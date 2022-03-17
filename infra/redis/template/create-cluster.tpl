#!/bin/bash

redis-cli -a a-very-complex-password-here --cluster create \
${ip1}:7000 \
${ip2}:7000 \
${ip3}:7000 \
${ip4}:7000 \
${ip5}:7000 \
${ip6}:7000 \
--cluster-replicas 1 \
--cluster-yes