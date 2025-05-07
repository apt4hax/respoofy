#!/bin/bash

blue()   { printf "\033[1;34m%s\033[0m" "$1"; }
pink()   { printf "\033[1;35m%s\033[0m" "$1"; }
yellow() { printf "\033[1;33m%s\033[0m" "$1"; }

SPF_RECORD="No Record Found"
SPF_ALL="Not Found"
SPF_DNS_COUNT="Not Found"
DMARC_RECORD="No Record Found"
DMARC_POLICY="Not Found"
DMARC_PCT="Not Found"
DMARC_ASPF="Not Found"
DMARC_SUB="Not Found"

while IFS= read -r line; do
    [[ "$line" == *"SPF record:"* ]] && SPF_RECORD="${line#*: }"
    [[ "$line" == *"SPF all record:"* ]] && SPF_ALL="${line#*: }"
    [[ "$line" == *"SPF DNS query count:"* ]] && SPF_DNS_COUNT="${line#*: }"
    [[ "$line" == *"DMARC record:"* ]] && [[ "$line" != *"No DMARC record found."* ]] && DMARC_RECORD="${line#*: }"
    [[ "$line" == *"Found DMARC policy:"* ]] && DMARC_POLICY="${line#*: }"
    [[ "$line" == *"DMARC pct:"* ]] && DMARC_PCT="${line#*: }"
    [[ "$line" == *"aspf found:"* ]] && DMARC_ASPF="${line#*: }"
    [[ "$line" == *"subdomain policy found:"* ]] && DMARC_SUB="${line#*: }"
done

blue "SPF Record: "; pink "$SPF_RECORD"; echo
blue "SPF ALL Mechanism: "; pink "$SPF_ALL"; echo
blue "SPF DNS Query Count: "; pink "$SPF_DNS_COUNT"; echo
blue "DMARC Record: "; pink "$DMARC_RECORD"; echo
blue "DMARC Policy: "; pink "$DMARC_POLICY"; echo
blue "DMARC pct: "; pink "$DMARC_PCT"; echo
blue "DMARC aspf: "; pink "$DMARC_ASPF"; echo
blue "DMARC Subdomain Policy: "; pink "$DMARC_SUB"; echo

echo
blue "Verdict: "
if [[ "$SPF_ALL" == "~all" || "$SPF_ALL" == "?all" ]]; then
    if [[ "$DMARC_POLICY" == "none" || "$DMARC_POLICY" == "Not Found" ]]; then
        pink "SPOOFABLE"; echo
        blue "Caveat: "; pink "May reach inbox or spam depending on recipient policies."; echo
        yellow "Reason: Weak SPF (~all) and no DMARC enforcement."; echo
    elif [[ "$DMARC_POLICY" == "quarantine" ]]; then
        pink "SPOOFABLE"; echo
        blue "Caveat: "; pink "Message likely quarantined or marked as spam."; echo
        yellow "Reason: SPF is weak, DMARC requests quarantine but does not reject."; echo
    elif [[ "$DMARC_POLICY" == "reject" ]]; then
        pink "LIMITED SPOOFING"; echo
        blue "Caveat: "; pink "Most spoofed emails will be rejected."; echo
        yellow "Reason: Weak SPF but strong DMARC policy (reject)."; echo
    fi
elif [[ "$SPF_ALL" == "-all" ]]; then
    if [[ "$DMARC_POLICY" == "none" || "$DMARC_POLICY" == "Not Found" ]]; then
        pink "PARTIALLY SPOOFABLE"; echo
        blue "Caveat: "; pink "Some providers may still accept spoofed messages."; echo
        yellow "Reason: Strong SPF but no DMARC policy allows partial spoofing."; echo
    elif [[ "$DMARC_POLICY" == "quarantine" ]]; then
        pink "REDUCED SPOOFING RISK"; echo
        blue "Caveat: "; pink "Spoofing may result in spam or quarantine."; echo
        yellow "Reason: Strong SPF and moderate DMARC reduce spoofing success."; echo
    else
        pink "NOT SPOOFABLE"; echo
        blue "Caveat: "; pink "Spoofed messages will likely be rejected."; echo
        yellow "Reason: SPF and DMARC both strictly enforced."; echo
    fi
else
    pink "UNKNOWN"; echo
    blue "Caveat: "; pink "Missing or unrecognized SPF configuration."; echo
    yellow "Reason: SPF record mechanism could not be evaluated."; echo
fi
