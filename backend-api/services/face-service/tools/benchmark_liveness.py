import argparse
import json
import statistics
import time
import urllib.request


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8001/internal/face/liveness/check")
    parser.add_argument("--request-file", required=True)
    parser.add_argument("--runs", type=int, default=5)
    args = parser.parse_args()

    with open(args.request_file, "r", encoding="utf-8") as file:
        payload = file.read().encode("utf-8")

    durations = []
    responses = []

    for _ in range(args.runs):
        request = urllib.request.Request(
            args.url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        started = time.perf_counter()
        with urllib.request.urlopen(request, timeout=10) as response:
            body = response.read().decode("utf-8")
        durations.append((time.perf_counter() - started) * 1000)
        responses.append(json.loads(body))

    print(
        json.dumps(
            {
                "runs": args.runs,
                "avgMs": round(statistics.mean(durations), 2),
                "minMs": round(min(durations), 2),
                "maxMs": round(max(durations), 2),
                "lastResponse": responses[-1],
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
