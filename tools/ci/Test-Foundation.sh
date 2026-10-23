#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/ieynec-foundation"
mkdir -p "$work"
xcrun swiftc browser/Reynard/Client/TabManagement/TabGroupStore.swift tests/tab-groups.test.swift -o "$work/tab-groups"
"$work/tab-groups"
xcrun swiftc browser/Reynard/Client/Search/SearchEngines.swift browser/Reynard/Client/Shared/URLUtils.swift tests/search-engines.test.swift -o "$work/search-engines"
"$work/search-engines"
