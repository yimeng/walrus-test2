#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${ROOT_DIR}/hack/lib/init.sh"

TEST_DIR="${ROOT_DIR}/.dist/test"
mkdir -p "${TEST_DIR}"

function test() {
  local target="$1"
  shift 1

  if [[ $# > 0 ]]; then
    for subdir in "$@"; do
      local path="${target}/${subdir}"
      local tfs
      tfs=$(seal::util::find_files "${path}" "*.tf")

      if [[ -n "${tfs}" ]]; then
        seal::terraform::test "${path}"
      else
        seal::log::warn "There is no Terraform files under ${path}"
      fi
    done
    
    return 0
  fi

  seal::terraform::test "${target}"
  local examples=()
  # shellcheck disable=SC2086
  IFS=" " read -r -a examples <<<"$(seal::util::find_subdirs ${target}/examples)"
  for example in "${examples[@]}"; do
    seal::terraform::test "${target}/examples/${example}"
  done
}

#
# main
#

seal::log::info "+++ TEST +++"

test "${ROOT_DIR}" "$@"

seal::log::info "--- TEST ---"
