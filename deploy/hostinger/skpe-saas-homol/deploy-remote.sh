#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="./deploy-state.env"
PUBLIC_CONTAINER="sparks-homol"
PREVIEW_CONTAINER="sparks-homol-preview"
RELEASE_PREFIX="/docker/skpe-saas-homol-"
ROLLBACK_AFTER_DEPLOY_EXIT_CODE=1
ROLLBACK_FAILURE_EXIT_CODE=2

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
  log "FINAL DEPLOY RESULT: FAIL - $*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

load_env() {
  [ -f ./.env ] || fail "Missing .env in release directory"
  set -a
  . ./.env
  set +a
}

validate_public_domain() {
  local body_file
  body_file="$(mktemp)"
  local curl_args=(
    --insecure
    --fail
    --silent
    --show-error
    --location
    --resolve "${SPARKS_PUBLIC_HOST}:443:127.0.0.1"
  )

  if ! curl "${curl_args[@]}" "https://${SPARKS_PUBLIC_HOST}/healthz" > /dev/null; then
    rm -f "${body_file}"
    return 1
  fi

  if ! curl "${curl_args[@]}" "https://${SPARKS_PUBLIC_HOST}/" > "${body_file}"; then
    rm -f "${body_file}"
    return 1
  fi

  if ! grep -Eq 'Plataforma SPARKs|<div id="root">' "${body_file}"; then
    rm -f "${body_file}"
    return 1
  fi

  rm -f "${body_file}"
  return 0
}

wait_for_public_domain() {
  local max_attempts="${1:-24}"
  local sleep_seconds="${2:-5}"
  local attempt=1

  while [ "${attempt}" -le "${max_attempts}" ]; do
    if validate_public_domain; then
      return 0
    fi

    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done

  return 1
}

wait_for_health() {
  local container_name="$1"
  local max_attempts="${2:-30}"
  local attempt=1
  local status

  while [ "${attempt}" -le "${max_attempts}" ]; do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' "${container_name}" 2>/dev/null || true)"

    if [ "${status}" = "healthy" ]; then
      return 0
    fi

    if [ "${status}" = "unhealthy" ]; then
      return 1
    fi

    sleep 5
    attempt=$((attempt + 1))
  done

  return 1
}

remove_preview_container() {
  docker rm -f "${PREVIEW_CONTAINER}" >/dev/null 2>&1 || true
}

validate_release_dir() {
  RELEASE_DIR="$(pwd -P)"

  [ -d "${RELEASE_DIR}" ] || fail "Current directory does not exist: ${RELEASE_DIR}"
  [ -n "${RELEASE_DIR}" ] || fail "Release directory is empty"

  case "${RELEASE_DIR}" in
    ${RELEASE_PREFIX}*)
      ;;
    *)
      fail "Release directory is outside expected prefix: ${RELEASE_DIR}"
      ;;
  esac

  [ "${RELEASE_DIR}" != "${RELEASE_PREFIX}" ] || fail "Release directory resolved to bare prefix"

  find "${RELEASE_DIR}" -mindepth 1 -maxdepth 1 -print -quit | grep -q . || \
    fail "Release directory is empty: ${RELEASE_DIR}"

  TARBALL_PATH="${RELEASE_DIR}/source/skpe-saas-${RELEASE_SHORT_SHA}.tar.gz"
  [ -f "${TARBALL_PATH}" ] || fail "Source bundle not found: ${TARBALL_PATH}"
}

write_cleanup_metadata() {
  {
    echo "BACKUP_CONTAINER=${BACKUP_CONTAINER}"
    echo "PREVIOUS_CONTAINER=${PUBLIC_CONTAINER}"
    echo "CURRENT_IMAGE=${CURRENT_IMAGE}"
    echo "CURRENT_RELEASE_DIR=${CURRENT_RELEASE_DIR}"
    echo "CURRENT_RELEASE_COMMIT=${CURRENT_RELEASE_COMMIT}"
    echo "CURRENT_RELEASE_TAG=${CURRENT_RELEASE_TAG}"
    echo "DEPLOY_TIMESTAMP=${DEPLOY_TIMESTAMP}"
    echo "NEW_RELEASE_DIR=${RELEASE_DIR}"
    echo "NEW_IMAGE=${IMAGE_NAME}"
    echo "GITHUB_SHA=${GITHUB_SHA}"
  } > "${STATE_FILE}"

  printf '%s\n' \
    "PREVIOUS_CONTAINER=${PUBLIC_CONTAINER}" \
    "CURRENT_IMAGE=${CURRENT_IMAGE}" \
    "CURRENT_RELEASE_DIR=${CURRENT_RELEASE_DIR}" \
    "CURRENT_RELEASE_COMMIT=${CURRENT_RELEASE_COMMIT}" \
    "CURRENT_RELEASE_TAG=${CURRENT_RELEASE_TAG}" \
    "BACKUP_CONTAINER=${BACKUP_CONTAINER}" \
    "DEPLOY_TIMESTAMP=${DEPLOY_TIMESTAMP}" \
    > ROLLBACK_PREP.txt

  printf '%s\n' \
    "docker rm -f ${PUBLIC_CONTAINER} >/dev/null 2>&1 || true" \
    "docker rm -f ${PREVIEW_CONTAINER} >/dev/null 2>&1 || true" \
    "docker rename ${BACKUP_CONTAINER} ${PUBLIC_CONTAINER}" \
    "docker start ${PUBLIC_CONTAINER}" \
    > ROLLBACK_COMMAND.txt
}

cleanup_failed_release() {
  log "FAILED RELEASE CLEANUP START"
  remove_preview_container
  docker image rm -f "${IMAGE_NAME}" >/dev/null 2>&1 || true

  if [ -n "${RELEASE_DIR:-}" ] && [ -d "${RELEASE_DIR}" ]; then
    case "${RELEASE_DIR}" in
      ${RELEASE_PREFIX}*)
        cd /docker
        rm -rf -- "${RELEASE_DIR}"
        ;;
      *)
        log "FAILED RELEASE CLEANUP SKIPPED: release directory outside expected prefix"
        ;;
    esac
  fi

  log "FAILED RELEASE CLEANUP PASS"
}

perform_rollback() {
  local restore_ok=0

  [ -f "${STATE_FILE}" ] || {
    log "ROLLBACK FAILED: state file not found"
    return 1
  }

  # shellcheck disable=SC1090
  . "${STATE_FILE}"

  log "ROLLBACK START"
  docker rm -f "${PUBLIC_CONTAINER}" >/dev/null 2>&1 || true
  remove_preview_container

  if docker ps -a --format '{{.Names}}' | grep -qx "${BACKUP_CONTAINER}"; then
    docker rename "${BACKUP_CONTAINER}" "${PUBLIC_CONTAINER}"
    docker start "${PUBLIC_CONTAINER}" >/dev/null

    if wait_for_health "${PUBLIC_CONTAINER}" 30 && wait_for_public_domain 24 5; then
      restore_ok=1
    fi
  fi

  if [ "${restore_ok}" -eq 1 ]; then
    log "ROLLBACK SUCCEEDED"
    return 0
  fi

  log "ROLLBACK FAILED"
  return 1
}

run_preflight() {
  require_command docker
  require_command curl
  require_command tar
  require_command grep
  require_command find

  docker inspect "${PUBLIC_CONTAINER}" >/dev/null 2>&1 || fail "Current public container does not exist"

  CURRENT_RUNNING="$(docker inspect --format '{{.State.Running}}' "${PUBLIC_CONTAINER}" 2>/dev/null || true)"
  [ "${CURRENT_RUNNING}" = "true" ] || fail "Current public container is not running"

  CURRENT_HEALTH="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' "${PUBLIC_CONTAINER}" 2>/dev/null || true)"
  [ "${CURRENT_HEALTH}" = "healthy" ] || fail "Current public container is not healthy"

  CURRENT_IMAGE="$(docker inspect --format '{{.Config.Image}}' "${PUBLIC_CONTAINER}" 2>/dev/null || true)"
  [ -n "${CURRENT_IMAGE}" ] || fail "Current public image could not be identified"

  CURRENT_RELEASE_DIR="$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "${PUBLIC_CONTAINER}" 2>/dev/null || true)"
  CURRENT_RELEASE_COMMIT="unknown"
  CURRENT_RELEASE_TAG="${CURRENT_IMAGE##*:}"
  DEPLOY_TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"

  if [ -n "${CURRENT_RELEASE_DIR}" ] && [ -f "${CURRENT_RELEASE_DIR}/source/app/COMMIT_SHA" ]; then
    CURRENT_RELEASE_COMMIT="$(tr -d '\n' < "${CURRENT_RELEASE_DIR}/source/app/COMMIT_SHA")"
  fi
}

build_preview_release() {
  log "RELEASE_SHA=${RELEASE_SHORT_SHA}"
  log "CURRENT IMAGE=${CURRENT_IMAGE}"
  log "NEW IMAGE=${IMAGE_NAME}"

  remove_preview_container
  rm -rf -- "${RELEASE_DIR}/source/app"
  mkdir -p "${RELEASE_DIR}/source/app"
  tar -xzf "${TARBALL_PATH}" -C "${RELEASE_DIR}/source/app"
  printf '%s\n' "${GITHUB_SHA}" > "${RELEASE_DIR}/source/app/COMMIT_SHA"

  if ! docker compose -f docker-compose.preview.yml up -d --build --force-recreate; then
    log "PREVIEW FAIL: docker compose preview build failed"
    cleanup_failed_release
    exit 1
  fi

  if ! wait_for_health "${PREVIEW_CONTAINER}" 60; then
    log "PREVIEW FAIL: preview container did not become healthy"
    cleanup_failed_release
    exit 1
  fi

  if ! curl --fail --silent --show-error "http://${PREVIEW_BIND%:*}/healthz" > /dev/null; then
    log "PREVIEW FAIL: preview /healthz did not return 200"
    cleanup_failed_release
    exit 1
  fi

  log "PREVIEW PASS"
}

cutover_release() {
  BACKUP_CONTAINER="${PUBLIC_CONTAINER}-old-${DEPLOY_TIMESTAMP}"
  write_cleanup_metadata

  if docker ps -a --format '{{.Names}}' | grep -qx "${PUBLIC_CONTAINER}"; then
    log "CUTOVER START"
    docker stop "${PUBLIC_CONTAINER}" >/dev/null 2>&1 || true
    docker rename "${PUBLIC_CONTAINER}" "${BACKUP_CONTAINER}"
  fi

  if ! docker compose -f docker-compose.yml up -d --force-recreate; then
    log "CUTOVER FAIL: public container compose up failed"
    if perform_rollback; then
      cleanup_failed_release
      exit "${ROLLBACK_AFTER_DEPLOY_EXIT_CODE}"
    fi

    cleanup_failed_release
    exit "${ROLLBACK_FAILURE_EXIT_CODE}"
  fi

  if ! wait_for_health "${PUBLIC_CONTAINER}" 60; then
    log "CUTOVER FAIL: new public container did not become healthy"
    if perform_rollback; then
      cleanup_failed_release
      exit "${ROLLBACK_AFTER_DEPLOY_EXIT_CODE}"
    fi

    cleanup_failed_release
    exit "${ROLLBACK_FAILURE_EXIT_CODE}"
  fi

  if ! wait_for_public_domain 24 5; then
    log "CUTOVER FAIL: public domain validation failed"
    if perform_rollback; then
      cleanup_failed_release
      exit "${ROLLBACK_AFTER_DEPLOY_EXIT_CODE}"
    fi

    cleanup_failed_release
    exit "${ROLLBACK_FAILURE_EXIT_CODE}"
  fi

  remove_preview_container
  log "CUTOVER PASS"
  log "FINAL DEPLOY RESULT: PASS"
}

manual_rollback() {
  if perform_rollback; then
    exit 0
  fi

  exit 1
}

if [ "${1:-}" = "rollback" ]; then
  load_env
  manual_rollback
fi

[ -n "${GITHUB_SHA:-}" ] || fail "GITHUB_SHA is required"
[ -n "${RELEASE_SHORT_SHA:-}" ] || fail "RELEASE_SHORT_SHA is required"

validate_release_dir
load_env
run_preflight
build_preview_release
cutover_release
