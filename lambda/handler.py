"""Lambda: składa stronę "Raport dla {{IMIE}}" z szablonu trzymanego w S3.

Wywołanie przez Lambda Function URL (payload format 2.0):
    GET /?imie=Ola  -> 200, text/html
    GET /           -> 400, podpowiedź
"""
import html
import os

import boto3

BUCKET = os.environ.get("TEMPLATE_BUCKET", "raport-koszykow-szablony")
KEY = os.environ.get("TEMPLATE_KEY", "template.html")
PLACEHOLDER = "{{IMIE}}"

# W LocalStack zmienna AWS_ENDPOINT_URL jest ustawiana automatycznie,
# więc boto3 sam kieruje żądania do emulatora.
s3 = boto3.client("s3")


def _response(status, body, content_type="text/html; charset=utf-8"):
    return {
        "statusCode": status,
        "headers": {"Content-Type": content_type},
        "body": body,
    }


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    imie = (params.get("imie") or "").strip()

    if not imie:
        return _response(
            400,
            "Brak parametru imie. Dopisz go do adresu, np. ?imie=Ola",
            "text/plain; charset=utf-8",
        )

    # Szablon pobierany przy KAŻDYM żądaniu – zmiana w S3 jest widoczna od razu,
    # bez ponownego wdrażania funkcji.
    template = s3.get_object(Bucket=BUCKET, Key=KEY)["Body"].read().decode("utf-8")

    # html.escape: znaki < > & " ' wyświetlają się jako tekst, a nie jako kod HTML
    page = template.replace(PLACEHOLDER, html.escape(imie, quote=True))
    return _response(200, page)
