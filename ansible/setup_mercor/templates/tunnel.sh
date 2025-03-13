#!/bin/bash
ssh -fN -L 3000:localhost:3000 {{ user_name }}@{{ inventory_hostname }}