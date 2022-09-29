name: Trigger update to docs

on:
  push:
    branches:
      - main
    paths:
      - '**.md'

jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger partners.pactflow.io update workflow
        run: |
          curl -X POST https://api.github.com/repos/pactflow/partners.pactflow.io/dispatches \
                -H 'Accept: application/vnd.github.everest-preview+json' \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -d '{"event_type": "pactflow-example-bi-directional-provider-dredd-updated"}'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN  }}
      - name: Trigger docs.pactflow.io update workflow
        run: |
          curl -X POST https://api.github.com/repos/pactflow/docs.pactflow.io/dispatches \
                -H 'Accept: application/vnd.github.everest-preview+json' \
                -H "Authorization: Bearer $GITHUB_TOKEN" \
                -d '{"event_type": "pactflow-example-bi-directional-provider-dredd-updated"}'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN  }}
