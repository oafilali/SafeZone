# Local SonarQube & ngrok Setup for SafeZone Pipeline

## Why run this script?

Before triggering the Jenkins pipeline, you must have a local SonarQube instance running and accessible to Jenkins (which runs remotely). This script ensures:

- SonarQube is running locally (via Docker Compose)
- ngrok is installed and exposes your local SonarQube to the internet
- You get the public ngrok URL to use in the pipeline.

## How to use

1. Open a terminal in the project root.
2. Run the setup script:
   ```sh
   cd .pipeline
   ./setup-local-sonarqube-ngrok.sh
   ```
   (If you get a permission error, run `chmod +x setup-local-sonarqube-ngrok.sh` first.)

## What happens next?

- The script checks for Docker, Docker Compose, and ngrok, installing ngrok if needed (on macOS).
- It starts SonarQube and its database using Docker Compose (if not already running).
- It starts ngrok to expose SonarQube on port 9000 (if not already running).
- It prints the public ngrok URL (e.g., `https://xxxx.ngrok-free.dev`).

## Final steps for the pipeline

1. Copy the ngrok public URL printed by the script.
2. In Jenkins, set the `SONARQUBE_URL_OVERRIDE` pipeline parameter to this URL (or leave the default if it matches).
3. Trigger the pipeline as usual (e.g., by pushing to GitHub).
4. Keep your local SonarQube and ngrok running until the pipeline completes the SonarQube analysis stage.

---

**Note:**

- If you restart your machine or close ngrok, you must re-run this script before triggering the pipeline again.
- If you are not on macOS, install ngrok manually from https://ngrok.com/download.
