# OpenSearch Observability Architecture Overview

This architecture is built to observe a legacy application that runs on VMs across AWS, Azure, and GCP based on GCVE for on prem workloads. Since the traffic is very spiky and the application is not container based, the design focuses on collecting logs, metrics, and traces in a simple and reliable way without depending on the app platform itself.

## How It Works

The application runs inside VMs or EC2 instances and uses auto instrumentation to generate metrics and traces. Logs are forwarded directly from the application host into Fluent Bit, which acts as the first collection point. At this stage, logs are tagged and categorized so different types of events can be treated differently.

From there, the data is split based on sensitivity. PII traffic is identified through custom headers and sent privately through AWS Direct Connect. Non PII traffic can move over HTTPS through the internet. This helps protect sensitive data while still keeping the overall pipeline flexible.

Inside AWS, Fluent Bit receives the incoming logs and works with FireLens to route them to the right downstream services. Non PII data is passed to Data Prepper, where it can be enriched and prepared for indexing. The processed data is then stored in Amazon OpenSearch, which becomes the main search and analysis layer for operational visibility.

Some important log streams, such as audit logs, PII related logs, exceptions, errors, warnings, and other critical infrastructure logs, are also routed into supporting storage services for retention and investigation. Grafana sits on top of the observability stack to query OpenSearch and provide dashboards for teams to monitor system health and troubleshoot issues quickly.

In short, the architecture separates collection, filtering, transport, processing, storage, and visualization into clear stages. That makes it easier to handle bursty traffic, protect sensitive information, and keep observability consistent even though the application is spread across different VM environments.

## Benefits Of This Architecture

This design gives the team one central observability flow for a legacy application that lives across multiple clouds and on prem style infrastructure. It supports sensitive and non sensitive traffic differently, which improves security and compliance. It also fits well for spiky traffic because the pipeline is decoupled, so collection, processing, and visualization are not all tied directly to the application hosts.

Another big benefit is operational clarity. OpenSearch provides a searchable store for observability data, while Grafana gives teams a clean way to view dashboards and investigate incidents. The result is a setup that is practical for legacy VM based systems without forcing a major application rewrite.

## Optimizations

I improved the efficiency of this architecture by tuning buffering and back pressure in Fluent Bit so sudden traffic spikes can be handled more smoothly without overwhelming downstream services. I also optimized the Data Prepper pipeline to avoid unnecessary enrichment on low value logs, which helped reduce processing overhead and indexing cost.

I refined log sampling and retention so very noisy exception and infrastructure logs can be filtered better and moved to lower cost storage when they are no longer needed for active investigation. On the OpenSearch side, I focused on index lifecycle tuning, shard sizing, and better hot and warm data separation to improve performance and cost efficiency.

I also looked at scaling on the AWS side so telemetry collection and processing can respond better during peak bursts while keeping normal usage more controlled.
