#!/bin/sh
# Sieve filter configuration pour serveur IMAP compatible Dovecot

require ["fileinto", "reject"];

# Spam et Phishing scoring
if header :value "ge" "X-Rspamd-Score" "7" {
    fileinto "Spam";
    stop;
}

if header :contains "X-Spam-Flag" "YES" {
    fileinto "Spam";
    stop;
}

# Phishing detection
if header :contains "X-Rspamd-Report" "PHISHING" {
    fileinto "Spam";
    stop;
}

# Authentication failures
if header :contains "X-Rspamd-Action" "reject" {
    fileinto "Spam";
    stop;
}

# Moderate spam scores
if header :value "ge" "X-Rspamd-Score" "5" {
    fileinto "Filtered";
    stop;
}

# Default: to read
fileinto "ToRead";
