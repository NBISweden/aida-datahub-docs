# Sending emails from DSP

DSP supports email deliveries but to limit exfiltration possibilities, there
are additional steps that need to be done to make it work.

## How it works

A list of allowed outgoing addresses can be registered for a secure
environment. These are then possible to use as sender for outgoing emails.
Emails with a different sender will be rejected.

## Requirements

To support outgoing emails, you'll need to provide

- a list of email addresses that will be used as sender addresses
- for each such outgoing address, the outgoing email details to use:
  - server
  - credentials (username and password) that are allowed to send emails
    with the outgoing address

We strongly encourage using separate accounts.

## Setup

Currently this requires manual interaction, contact DSP support to set
things up.

## Use

Once you have confirmation that the setup is done, you can use 10.253.254.250
as SMTP server. You do NOT need to provide authentication but we strongly
encourage using encryption (TLS) for these connection, either using `smtps`
or SMTP with `STARTTLS`.
