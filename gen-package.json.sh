#!/bin/sh
cat > package.json << EOF
{
    "name": "pkman-${SYSTEM_NAME}-${ARCHITECTURE}",
    "version": "${VERSION}",
    "description": "The package manager.",
    "type": "package-manager",
    "operatingSystem": "${SYSTEM_NAME}",
    "architecture": "${ARCHITECTURE}",
    "mainExecutables":
    {
        "pkman${EXECUTABLE_POSTFIX}": { "headless": true },
        "pkman-gui${EXECUTABLE_POSTFIX}": {}
    },
    "provides":
    {
        "pkman": "${VERSION}"
    }
}
EOF
