#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

function generate() {
  local mode="${1:-all}"

  case $mode in
    docs)
      shift 1
      generate_doc "${ROOT_DIR}" "$@"
      ;;
    schema)
      shift 1
      generate_schema "${ROOT_DIR}" "$@"
      ;;
    *)
      generate_doc "${ROOT_DIR}" "$@"
      generate_schema "${ROOT_DIR}" "$@"
      ;;
  esac
}

function generate_doc() {
  local target="$1"
  shift 1

  if [[ $# > 0 ]]; then
    for subdir in "$@"; do
      local path="${target}/${subdir}"
      local tfs
      tfs=$(seal::util::find_files "${path}" "*.tf")

      if [[ -n "${tfs}" ]]; then
        seal::terraform::docs "${path}" --config="${target}/.terraform-docs.yml"
      else
        seal::log::warn "There is no Terraform files under ${path}"
      fi
    done

    return 0
  fi

  seal::terraform::docs "${target}" --config="${target}/.terraform-docs.yml" --recursive
  local examples=()
  # shellcheck disable=SC2086
  IFS=" " read -r -a examples <<<"$(seal::util::find_subdirs ${target}/examples)"
  for example in "${examples[@]}"; do
    seal::terraform::docs "${target}/examples/${example}" --config="${target}/.terraform-docs.yml"
  done
}

function generate_schema() {
  local target="$1"
  shift 1

  if [[ $# > 0 ]]; then
    for subdir in "$@"; do
      local path="${target}/${subdir}"
      local tfs
      tfs=$(seal::util::find_files "${path}" "*.tf")

      if [[ -n "${tfs}" ]]; then
        seal::walrus_cli::schema "${target}"
      else
        seal::log::warn "There is no Terraform files under ${path}"
      fi
    done

    return 0
  fi

  seal::walrus_cli::schema "${target}"
  local sub_modules=()
  # shellcheck disable=SC2086
  IFS=" " read -r -a sub_modules <<<"$(seal::util::find_subdirs ${target}/modules)"
  for module in "${sub_modules[@]}"; do
    seal::walrus_cli::schema "${target}/modules/${module}"
  done
}

#
# main
#

seal::log::info "+++ GENERATE +++"

generate "$@"

seal::log::info "--- GENERATE ---"
