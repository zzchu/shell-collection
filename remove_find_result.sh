#!/usr/bash
find . -name *.gcda -exec rm -f {} \;
find . ! -name "*.h" -type f -exec rm -f {} \;

cat wme-jenkins.txt | grep "Failed \|Success \|Aborted " > out.txt