#!/bin/bash

DSPACE="/dspace/bin/dspace"

$DSPACE community-create \
  --name "School of Engineering"

$DSPACE community-create \
  --name "School of Applied Sciences"

$DSPACE community-create \
  --name "School of Commerce"

$DSPACE community-create \
  --name "School of Hospitality and Tourism"

$DSPACE community-create \
  --name "School of Art and Design"

$DSPACE community-create \
  --name "School of Information and Communication Technology"

$DSPACE community-create \
  --name "Library and Institutional Publications"

echo "Communities created."
