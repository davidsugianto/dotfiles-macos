# prompt-forge examples

Three worked examples: a code task, a prose task, and a vague request.

## Example 1: Code task (bash backup script)

**Input**

```
tolong bikinin script bash buat backup db postgres tiap malem, simpen 7 hari aja, kalo gagal kirim notif ke slack
```

**Output**

```
## Task
Write a bash script that backs up a PostgreSQL database every night, keeps the last 7 days of backups, and sends a Slack notification when a backup fails.

## Context
- The script runs unattended on a single host.
- Database: `[DB_NAME]` on `[DB_HOST]`, user `[DB_USER]`. The password comes from `PGPASSWORD` or `~/.pgpass`, never from the script body.
- Backups go to `[BACKUP_DIR]`.
- Failure alerts go to the Slack incoming webhook `[SLACK_WEBHOOK_URL]`.

## Requirements
- Use `pg_dump` with a compressed custom-format dump. Name files `[DB_NAME]_YYYY-MM-DD_HHMMSS.dump`.
- Start with `set -euo pipefail`. Write to a temp file first and move it into place only after `pg_dump` exits 0, so a failed run leaves no partial file.
- Delete backups in `[BACKUP_DIR]` older than 7 days, and only after a successful backup.
- On any failure, post the hostname, database name, timestamp and exit code to the Slack webhook with `curl`. Do not print the webhook URL in logs.
- Log each run to stdout with timestamps.
- Show one scheduling line for cron that runs the script at `[RUN_TIME]` every night.

## Output format
Return the script in one bash code block, then the cron line in a second block. Add at most five lines of usage notes after them.
```

**Assumptions**
- Pakai `pg_dump` format custom (`-Fc`), bukan SQL polos.
- Dijalankan lewat cron, bukan launchd. Kalo di macOS dan mau launchd, bilang aja.
- Backup disimpan di satu direktori lokal, retensi dihitung dari umur file (7 hari).
- Password diambil dari `PGPASSWORD` atau `~/.pgpass`.

**Placeholders to fill**
- `[DB_NAME]`, `[DB_HOST]`, `[DB_USER]`
- `[BACKUP_DIR]`
- `[SLACK_WEBHOOK_URL]`
- `[RUN_TIME]` (jam backup malam)

Why: it is a code task, so the prompt has no writing block. Style rules for prose would add noise.

## Example 2: Prose task (delay email)

**Input**

```
gw mau email ke client bilang deploy-nya delay 2 hari karena ada bug di payment, tapi jangan kesannya kita gak kompeten
```

**Output**

```
## Task
Write an email to a client saying the deployment is delayed by 2 days because of a bug in the payment flow. The email should read as careful and in control, not as an admission of poor quality.

## Context
- Recipient: `[CLIENT_NAME]` at `[CLIENT_COMPANY]`.
- Sender: `[SENDER_NAME]`, `[SENDER_ROLE]`.
- Original deploy date: `[ORIGINAL_DATE]`. New deploy date: `[NEW_DATE]`.
- The cause is a bug in the payment flow. How and when it was found: `[HOW_BUG_WAS_FOUND]`.

## Requirements
- Subject line states the new date.
- Open with the delay and the new date in the first two sentences.
- Say only what `[HOW_BUG_WAS_FOUND]` confirms about the bug. If it was caught before release, say that holding the release protects the client's payments. Do not claim customer impact either way.
- Do not blame a person or a vendor. Do not over-apologize. One short apology is enough.
- Give the client one concrete next step, such as a confirmation message on `[NEW_DATE]`.
- Do not promise anything about the fix that the sender has not confirmed.

## Output format
One email: subject line, greeting, body of 3 short paragraphs at most, sign-off with the sender's name. Return only the email text.

## Writing rules
- Use plain words and short sentences.
- Avoid stock AI phrases such as "delve", "tapestry", "seamless" and "it's important to note".
- Do not force lists of three or stack em-dashes.
- Do not end with a recap or an offer to help further.
- No emojis.
- Prefer concrete facts (dates, what broke, what happens next) over general reassurance.
- Match a professional but warm tone for a client the sender already works with.
```

**Assumptions**
- Nada: profesional tapi hangat, bukan formal kaku.
- Panjang: maksimal 3 paragraf pendek.
- Kamu tidak bilang bug-nya ditemukan kapan dan bagaimana, jadi itu jadi placeholder, bukan diasumsikan "sebelum rilis".
- Email dalam bahasa Inggris.

**Placeholders to fill**
- `[CLIENT_NAME]`, `[CLIENT_COMPANY]`
- `[ORIGINAL_DATE]`, `[NEW_DATE]`
- `[HOW_BUG_WAS_FOUND]` (kapan dan bagaimana bug ketemu, misalnya saat testing sebelum rilis)
- `[SENDER_NAME]`, `[SENDER_ROLE]`

Why: the output is prose for a human reader, so it gets the style block that keeps the email from sounding generated.

## Example 3: Vague input (questions only)

**Input**

```
bikin prompt buat analisa data
```

**Output**

Sebelum bikin prompt-nya, saya perlu tahu tiga hal:

1. Datanya apa dan formatnya apa (misalnya CSV penjualan, log aplikasi, hasil survei)?
2. Pertanyaan apa yang mau dijawab dari data itu?
3. Hasil akhirnya seperti apa (ringkasan teks, tabel, grafik, atau kode analisis)?
