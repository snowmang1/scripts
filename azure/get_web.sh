#!/bin/bash

az storage account list | jq '.[] .primaryEndpoints.web'
