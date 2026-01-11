"""
Shared Ready Conditions for Sequential Tests

Standard condition sets for simulating resource readiness in sequential composition tests
using observedResources. These conditions represent the typical states that Crossplane
resources reach when successfully created and managed.

Usage Pattern:
-------------
In sequential tests (Pattern D), these conditions are used with observedResources to
simulate resources being ready, allowing tests to validate dependent resource creation.

Example:
    import conditions

    observedResources: [
        ec2v1beta1.VPC {
            **_vpcResource
            status: {
                atProvider: { id: "vpc-12345" }
                conditions: conditions.readyConditions
            }
        }
    ]

NOTE: Cross-directory imports in KCL have limitations. If importing from tests/shared/
doesn't work, copy this file into your test directory (e.g., tests/test-my-feature/conditions.k)
and import locally.

Reference: Crossplane v2 condition types
"""

import datetime


# Standard ready conditions for a successfully created and synced resource
readyConditions = [
    {
        reason: "Available"
        status: "True"
        type: "Ready"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "Success"
        status: "True"
        type: "LastAsyncOperation"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "ReconcileSuccess"
        status: "True"
        type: "Synced"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
]

# Conditions for a resource that exists but is not yet ready
pendingConditions = [
    {
        reason: "Creating"
        status: "False"
        type: "Ready"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "InProgress"
        status: "Unknown"
        type: "LastAsyncOperation"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "ReconcileInProgress"
        status: "True"
        type: "Synced"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
]

# Conditions for a failed resource
failedConditions = [
    {
        reason: "CreationFailed"
        status: "False"
        type: "Ready"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "Failed"
        status: "False"
        type: "LastAsyncOperation"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
    {
        reason: "ReconcileError"
        status: "False"
        type: "Synced"
        lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ")
    }
]
