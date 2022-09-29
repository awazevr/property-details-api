name: Test & Upload to Pactflow

on:
  push:
     branches:
      - main
  workflow_dispatch:
    inputs:
      PACT_CLI_DOCKER_VERSION:
        description:
        required: true
        default: latest

env:
  PACT_BROKER_BASE_URL: https://mackah.pactflow.io
  PACT_BROKER_TOKEN: ${{ secrets.PACTFLOW_TOKEN_FOR_CI_CD_WORKSHOP }}
  PACT_BROKER_PUBLISH_VERIFICATION_RESULTS: true
  GIT_COMMIT: ${{ github.sha }}
  GITHUB_REF: ${{ github.ref }}
  PACT_CLI_DOCKER_VERSION: ${{ github.event.inputs.PACT_CLI_DOCKER_VERSION }}

jobs:
  set-pact-cli-docker-version:
    name: 🐳 set-pact-cli-docker-version
    runs-on: ubuntu-latest
    steps:
      - if: ${{ env.PACT_CLI_DOCKER_VERSION == '' }}
        name: 🐳 set PACT_CLI_DOCKER_VERSION to latest, if version not present
        run: |
          PACT_CLI_DOCKER_VERSION="latest"
          echo "PACT_CLI_DOCKER_VERSION=${PACT_CLI_DOCKER_VERSION}" >> $GITHUB_ENV 
      - name: 🐳 PACT_CLI_DOCKER_VERSION is ${{ env.PACT_CLI_DOCKER_VERSION }}
        run: echo $PACT_CLI_DOCKER_VERSION
    outputs:
      PACT_CLI_DOCKER_VERSION: ${{ env.PACT_CLI_DOCKER_VERSION }}

  test:
    needs: [set-pact-cli-docker-version]
    strategy:
      fail-fast: false
      matrix:
        os: ['ubuntu-latest']
        node-version: [16.x]
    runs-on: ${{ matrix.os }}
    env:
      PACT_CLI_DOCKER_VERSION: ${{ needs.set-pact-cli-docker-version.outputs.PACT_CLI_DOCKER_VERSION}}
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - name: Install
        run: npm i
        shell: bash
      - name: Test
        run: GIT_BRANCH=${GITHUB_REF:11} make ci
        shell: bash
      # - name: Release
      #   env:
      #     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      #   run: npx semantic-release

  # Runs on branches as well, so we know the status of our PRs
  can-i-deploy:
    strategy:
      fail-fast: false
      matrix:
        os: ['ubuntu-latest']
    runs-on: ${{ matrix.os }}
    needs: [test, set-pact-cli-docker-version]
    env:
      PACT_CLI_DOCKER_VERSION: ${{ needs.set-pact-cli-docker-version.outputs.PACT_CLI_DOCKER_VERSION}}
    steps:
      - uses: actions/checkout@v3
      - name: 🔎 Can I deploy? 
        run: GIT_BRANCH=${GITHUB_REF:11} make can_i_deploy
        shell: bash

  # Only deploy from master
  deploy:
    strategy:
      fail-fast: false
      matrix:
        os: ['ubuntu-latest']
    runs-on: ${{ matrix.os }}
    needs: [can-i-deploy, set-pact-cli-docker-version]
    env:
      PACT_CLI_DOCKER_VERSION: ${{ needs.set-pact-cli-docker-version.outputs.PACT_CLI_DOCKER_VERSION}}
    steps:
      - uses: actions/checkout@v3
      - name: 🚀 Deploy
        run: GIT_BRANCH=${GITHUB_REF:11} make deploy
        if: github.ref == 'refs/heads/main'
        shell: bash
