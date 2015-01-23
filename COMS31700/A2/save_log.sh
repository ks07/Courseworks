#!/bin/sh

tr < irun.log -d '\000' > test_logs/seed_1_v$(git rev-parse --short HEAD).log