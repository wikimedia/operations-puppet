#!/bin/sh
# SPDX-License-Identifier: MIT
# This file is managed by Puppet (modules/kubeadm/files/kubectl-sudo.sh).
#
# Ignore some spellcheck rules, we want to stay
# as close to the original source as possible:
# shellcheck disable=SC3045,SC2081,SC2162,SC2086
#
# Original source:
# https://github.com/postfinance/kubectl-sudo
#
# MIT License
#
# Copyright (c) 2018 PostFinance AG
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


KUBECTL_SUDO_PROMPT=${KUBECTL_SUDO_PROMPT:-false}
if [ "$KUBECTL_SUDO_PROMPT" = true ]; then
    read -p "WARNING: Currently in context $(kubectl config current-context). Continue? (y/N) " yn
    case $yn in
        [Yy]* ) ;;
        * ) exit 1;;
    esac
fi

NEW_ARGS=""
PLUGIN_NAME=""
COMMAND=""

for arg in "$@"
do
    if [ ${arg} != "--"* ] && [ -z "${COMMAND}" ]; then
        COMMAND=${arg}
    fi
    plugin_path=$(which "kubectl-${COMMAND}" 2>/dev/null)
    if [ -x "${plugin_path}" ] && [ -z "${PLUGIN_NAME}" ]; then
        PLUGIN_NAME=$arg
        continue
    fi
    NEW_ARGS="${NEW_ARGS} ${arg}"
done

if [ -z "${PLUGIN_NAME}" ]; then
    exec kubectl --as=${USER} --as-group=system:masters "$@"
else
    exec kubectl ${PLUGIN_NAME} --as=${USER} --as-group=system:masters ${NEW_ARGS}
fi
