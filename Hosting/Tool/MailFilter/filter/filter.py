#!/usr/bin/env python3
"""
Mail Filter — Fetch IMAP INBOX, analyze with Rspamd + ClamAV, move to right folder.
"""
import imaplib
import os
import time
import logging
import requests
import clamd

# ── Config ────────────────────────────────────────────────────────────────────

IMAP_HOST     = os.environ["IMAP_HOST"]
IMAP_PORT     = int(os.environ.get("IMAP_PORT", 993))
IMAP_USER     = os.environ["IMAP_USER"]
IMAP_PASSWORD = os.environ["IMAP_PASSWORD"]

RSPAMD_HOST = os.environ.get("RSPAMD_HOST", "mail-rspamd")
RSPAMD_PORT = int(os.environ.get("RSPAMD_PORT", 11333))

CLAMAV_HOST = os.environ.get("CLAMAV_HOST", "mail-clamav")
CLAMAV_PORT = int(os.environ.get("CLAMAV_PORT", 3310))

FOLDER_INBOX        = os.environ.get("MAIL_INBOX",        "INBOX")
FOLDER_SPAM         = os.environ.get("MAIL_SPAM",         "Spam")
FOLDER_FILTERED     = os.environ.get("MAIL_FILTERED",     "Filtered")
FOLDER_TO_READ      = os.environ.get("MAIL_TO_READ",      "ToRead")
FOLDER_NOTIFICATION = os.environ.get("MAIL_NOTIFICATION", "Notification")

SPAM_THRESHOLD     = float(os.environ.get("SPAM_THRESHOLD",     5))
PHISHING_THRESHOLD = float(os.environ.get("PHISHING_THRESHOLD", 7))
SYNC_INTERVAL      = int(os.environ.get("SYNC_INTERVAL",        300))

logging.basicConfig(
    level=getattr(logging, os.environ.get("LOG_LEVEL", "INFO").upper()),
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Analysis ──────────────────────────────────────────────────────────────────

def check_rspamd(raw: bytes) -> dict:
    try:
        resp = requests.post(
            f"http://{RSPAMD_HOST}:{RSPAMD_PORT}/checkv2",
            data=raw,
            headers={"Content-Type": "message/rfc822"},
            timeout=10,
        )
        resp.raise_for_status()
        return resp.json()
    except Exception as e:
        log.warning(f"Rspamd unreachable: {e}")
        return {"score": 0.0, "action": "no action", "symbols": {}}


def check_clamav(raw: bytes) -> bool:
    """Returns True if clean, False if malware detected."""
    try:
        cd = clamd.ClamdNetworkSocket(host=CLAMAV_HOST, port=CLAMAV_PORT, timeout=15)
        result = cd.instream(raw)
        status = result.get("stream", ("OK", ""))[0]
        if status != "OK":
            log.warning(f"ClamAV hit: {result}")
            return False
        return True
    except Exception as e:
        log.warning(f"ClamAV unreachable (skipping): {e}")
        return True  # don't block mail if ClamAV is down


def decide_folder(rspamd: dict, is_clean: bool) -> str:
    if not is_clean:
        return FOLDER_SPAM

    score   = rspamd.get("score", 0.0)
    action  = rspamd.get("action", "no action")
    symbols = rspamd.get("symbols", {})

    if action == "reject" or "PHISHING" in symbols or score >= PHISHING_THRESHOLD:
        return FOLDER_SPAM
    if score >= SPAM_THRESHOLD:
        return FOLDER_FILTERED
    return FOLDER_TO_READ

# ── IMAP ──────────────────────────────────────────────────────────────────────

def process_inbox():
    log.info("Connecting to IMAP...")
    imap = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT)
    try:
        imap.login(IMAP_USER, IMAP_PASSWORD)
        imap.select(FOLDER_INBOX)

        _, data = imap.search(None, "UNSEEN")
        uids = data[0].split()

        if not uids:
            log.info("No new messages.")
            return

        log.info(f"{len(uids)} unseen message(s) found.")

        for uid in uids:
            _, msg_data = imap.fetch(uid, "(RFC822)")
            raw = msg_data[0][1]

            rspamd  = check_rspamd(raw)
            clean   = check_clamav(raw)
            score   = rspamd.get("score", 0.0)
            dest    = decide_folder(rspamd, clean)

            log.info(f"UID {uid.decode()} | score={score:.2f} | clean={clean} | → {dest}")

            imap.copy(uid, dest)
            imap.store(uid, "+FLAGS", "\\Deleted")

        imap.expunge()
        log.info(f"{len(uids)} message(s) processed.")
    finally:
        try:
            imap.logout()
        except Exception:
            pass

# ── Main loop ─────────────────────────────────────────────────────────────────

def main():
    log.info("=== Mail Filter Service started ===")
    log.info(f"IMAP     : {IMAP_USER} @ {IMAP_HOST}:{IMAP_PORT}")
    log.info(f"Rspamd   : {RSPAMD_HOST}:{RSPAMD_PORT}")
    log.info(f"ClamAV   : {CLAMAV_HOST}:{CLAMAV_PORT}")
    log.info(f"Thresholds: spam={SPAM_THRESHOLD} | phishing={PHISHING_THRESHOLD}")
    log.info(f"Interval : {SYNC_INTERVAL}s")

    while True:
        try:
            process_inbox()
        except Exception as e:
            log.error(f"Error: {e}")
        log.info(f"Next scan in {SYNC_INTERVAL}s...")
        time.sleep(SYNC_INTERVAL)


if __name__ == "__main__":
    main()
