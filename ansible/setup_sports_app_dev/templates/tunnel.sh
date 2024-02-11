#!/bin/bash
ssh -fN -L 1234:localhost:1234 -L 3000:localhost:3000 {{ user_name }}@{{ inventory_hostname }}