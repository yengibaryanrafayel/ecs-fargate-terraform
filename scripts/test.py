#!/usr/bin/env python3
"""
Unleash Live — Multi-Region API Test Script

Usage:
    python scripts/test.py \
        --us-api-url  https://<id>.execute-api.us-east-1.amazonaws.com \
        --eu-api-url  https://<id>.execute-api.eu-west-1.amazonaws.com \
        --user-pool-id  us-east-1_XXXXXXXXX \
        --client-id     XXXXXXXXXXXXXXXXXXXXXXXXXX \
        --email         your.email@example.com \
        --password      YourPassword123!

Dependencies:
    pip install boto3 requests
"""

import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import boto3
import requests
from botocore.exceptions import ClientError


# ─────────────────────────────────────────────────────────────
# Auth
# ─────────────────────────────────────────────────────────────

def authenticate(user_pool_id: str, client_id: str, email: str, password: str) -> str:
    """
    Authenticate with Cognito using USER_PASSWORD_AUTH and return an ID token.
    Automatically handles the NEW_PASSWORD_REQUIRED challenge (first-time login).
    """
    cognito = boto3.client("cognito-idp", region_name="us-east-1")

    print(f"\n[AUTH] Authenticating as {email} ...")

    try:
        resp = cognito.initiate_auth(
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": email, "PASSWORD": password},
            ClientId=client_id,
        )
    except ClientError as e:
        print(f"[AUTH] FAILED — {e}")
        raise

    # Terraform creates the user with a temporary password; handle mandatory reset.
    if resp.get("ChallengeName") == "NEW_PASSWORD_REQUIRED":
        print("[AUTH] Responding to NEW_PASSWORD_REQUIRED challenge ...")
        resp = cognito.respond_to_auth_challenge(
            ClientId=client_id,
            ChallengeName="NEW_PASSWORD_REQUIRED",
            Session=resp["Session"],
            ChallengeResponses={"USERNAME": email, "NEW_PASSWORD": password},
        )

    token = resp["AuthenticationResult"]["IdToken"]
    print("[AUTH] OK — JWT obtained")
    return token


# ─────────────────────────────────────────────────────────────
# HTTP helpers
# ─────────────────────────────────────────────────────────────

def call(label: str, url: str, method: str, token: str, expected_region: str) -> dict:
    """Call one API endpoint, measure latency, return a result dict."""
    headers = {"Authorization": token, "Content-Type": "application/json"}
    t0 = time.monotonic()
    try:
        fn = requests.get if method == "GET" else requests.post
        r = fn(url, headers=headers, timeout=30)
        latency = round((time.monotonic() - t0) * 1000, 1)
        try:
            body = r.json()
        except Exception:
            body = {"raw": r.text}

        region_ok = body.get("region") == expected_region if "region" in body else None

        return {
            "label": label,
            "url": url,
            "http": r.status_code,
            "latency_ms": latency,
            "body": body,
            "expected_region": expected_region,
            "region_match": region_ok,
            "ok": r.status_code == 200,
        }
    except Exception as exc:
        latency = round((time.monotonic() - t0) * 1000, 1)
        return {
            "label": label,
            "url": url,
            "http": None,
            "latency_ms": latency,
            "error": str(exc),
            "expected_region": expected_region,
            "region_match": False,
            "ok": False,
        }


def print_result(r: dict) -> None:
    status = "PASS" if r["ok"] else "FAIL"
    region_tag = ""
    if r.get("region_match") is True:
        region_tag = f"  region='{r['body'].get('region')}' ✓ matches expected"
    elif r.get("region_match") is False and "body" in r:
        region_tag = (
            f"  region='{r['body'].get('region')}' ✗ expected '{r['expected_region']}'"
        )

    print(f"\n  ┌─ [{status}] {r['label']}")
    print(f"  │  URL     : {r['url']}")
    print(f"  │  HTTP    : {r['http']}")
    print(f"  │  Latency : {r['latency_ms']} ms")
    if region_tag:
        print(f"  │  Region  :{region_tag}")
    if "error" in r:
        print(f"  │  Error   : {r['error']}")
    elif "body" in r:
        print(f"  │  Body    : {json.dumps(r['body'])}")
    print(f"  └{'─'*60}")


# ─────────────────────────────────────────────────────────────
# Test runner
# ─────────────────────────────────────────────────────────────

def run(us_url: str, eu_url: str, user_pool_id: str, client_id: str,
        email: str, password: str) -> bool:

    token = authenticate(user_pool_id, client_id, email, password)

    tasks = [
        # /greet — both regions concurrently
        ("Greeter  us-east-1", f"{us_url.rstrip('/')}/greet",    "GET",  "us-east-1"),
        ("Greeter  eu-west-1", f"{eu_url.rstrip('/')}/greet",    "GET",  "eu-west-1"),
        # /dispatch — both regions concurrently
        ("Dispatch us-east-1", f"{us_url.rstrip('/')}/dispatch", "POST", "us-east-1"),
        ("Dispatch eu-west-1", f"{eu_url.rstrip('/')}/dispatch", "POST", "eu-west-1"),
    ]

    # ── Phase 1: /greet (concurrent) ──────────────────────────
    print(f"\n{'═'*64}")
    print("  PHASE 1 — /greet endpoints (concurrent)")
    print(f"{'═'*64}")
    greet_tasks = tasks[:2]
    greet_results = []

    with ThreadPoolExecutor(max_workers=2) as pool:
        futs = {
            pool.submit(call, label, url, method, token, region): (label, region)
            for label, url, method, region in greet_tasks
        }
        for fut in as_completed(futs):
            r = fut.result()
            greet_results.append(r)
            print_result(r)

    # ── Phase 2: /dispatch (concurrent) ───────────────────────
    print(f"\n{'═'*64}")
    print("  PHASE 2 — /dispatch endpoints (concurrent)")
    print(f"{'═'*64}")
    dispatch_tasks = tasks[2:]
    dispatch_results = []

    with ThreadPoolExecutor(max_workers=2) as pool:
        futs = {
            pool.submit(call, label, url, method, token, region): (label, region)
            for label, url, method, region in dispatch_tasks
        }
        for fut in as_completed(futs):
            r = fut.result()
            dispatch_results.append(r)
            print_result(r)

    # ── Summary ───────────────────────────────────────────────
    all_results = greet_results + dispatch_results
    passed = sum(1 for r in all_results if r["ok"])
    total = len(all_results)

    print(f"\n{'═'*64}")
    print(f"  RESULTS  {passed}/{total} tests passed")

    # Latency comparison (geographic performance evidence)
    us_g = next((r for r in greet_results if "us-east-1" in r["label"]), None)
    eu_g = next((r for r in greet_results if "eu-west-1" in r["label"]), None)
    if us_g and eu_g:
        diff = abs(us_g["latency_ms"] - eu_g["latency_ms"])
        print(f"\n  LATENCY COMPARISON (/greet):")
        print(f"    us-east-1 : {us_g['latency_ms']:>8.1f} ms")
        print(f"    eu-west-1 : {eu_g['latency_ms']:>8.1f} ms")
        print(f"    difference: {diff:>8.1f} ms  ← geographic spread")

    print(f"{'═'*64}\n")
    return passed == total


# ─────────────────────────────────────────────────────────────
# CLI entry point
# ─────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Unleash Live multi-region API integration test"
    )
    parser.add_argument("--us-api-url",   required=True, help="API URL for us-east-1")
    parser.add_argument("--eu-api-url",   required=True, help="API URL for eu-west-1")
    parser.add_argument("--user-pool-id", required=True, help="Cognito User Pool ID")
    parser.add_argument("--client-id",    required=True, help="Cognito App Client ID")
    parser.add_argument("--email",        required=True, help="Test user email")
    parser.add_argument("--password",     required=True, help="Test user password")
    args = parser.parse_args()

    success = run(
        us_url=args.us_api_url,
        eu_url=args.eu_api_url,
        user_pool_id=args.user_pool_id,
        client_id=args.client_id,
        email=args.email,
        password=args.password,
    )
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
