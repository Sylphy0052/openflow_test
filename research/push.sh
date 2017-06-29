#!/bin/bash

read -p "Please input commit message: " commit_message

echo "git add ."
git add .
echo "git commit -m \"$commit_message\""
git commit -m "$commit_message"
echo "git push"
git push
