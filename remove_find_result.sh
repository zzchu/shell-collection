#!/usr/bash
find . -name *.gcda -exec rm -f {} \;

cat wme-jenkins.txt | grep "Failed \|Success \|Aborted " > out.txt