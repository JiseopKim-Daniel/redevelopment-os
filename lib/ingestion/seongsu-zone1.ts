import "server-only";

import { createAdminClient } from "@/lib/supabase/admin";

const AREA_SLUG = "seongsu-strategic-zone-1";
const SOURCE_IDENTIFIER = "cafeId=200100002009a28";
const FACT_TYPE = "project_stage";
const ATTRIBUTE_KEY = "association_establishment_approval";
const EFFECTIVE_DATE = "2017-07-18";
const COLLECTION_METHOD = "server_fixture_validation";
const COLLECTOR_VERSION = "phase2-server-v1";
const PARSER_VERSION = "phase2-server-parser-v1";

export type SeongsuZone1Fixture = {
  area_slug: typeof AREA_SLUG;
  source_identifier: typeof SOURCE_IDENTIFIER;
  source_system: "서울특별시 정비사업 정보몽땅";
  project_title: "성수전략정비구역 제1 주택정비형 재개발정비사업조합";
  displayed_stage: "조합설립인가";
  approval_date: typeof EFFECTIVE_DATE;
  fact_type: typeof FACT_TYPE;
  attribute_key: typeof ATTRIBUTE_KEY;
  stage_code: typeof ATTRIBUTE_KEY;
  stage_label: "조합설립인가";
};

export type SeongsuZone1IngestionResult = {
  ingestionRunId: string;
  rawObservationId: string;
  normalizedObservationId: string;
  reviewRecordId: string;
  valueChanged: boolean;
  status: "succeeded";
};

type PublishedFactRow = {
  id: string;
  published_value: unknown;
  effective_from: string | null;
};

type AuditInput = {
  eventType: string;
  actorLabel: string;
  entityType: string;
  entityId: string;
  ingestionRunId: string;
  changeSummary: Record<string, unknown>;
  reason: string;
};

type SafeWorkflowError = Error & {
  code?: string;
  details?: string;
  hint?: string;
};

const fixture: SeongsuZone1Fixture = {
  area_slug: AREA_SLUG,
  source_identifier: SOURCE_IDENTIFIER,
  source_system: "서울특별시 정비사업 정보몽땅",
  project_title: "성수전략정비구역 제1 주택정비형 재개발정비사업조합",
  displayed_stage: "조합설립인가",
  approval_date: EFFECTIVE_DATE,
  fact_type: FACT_TYPE,
  attribute_key: ATTRIBUTE_KEY,
  stage_code: ATTRIBUTE_KEY,
  stage_label: "조합설립인가",
};

const normalizedValue = {
  stage_code: fixture.stage_code,
  stage_label: fixture.stage_label,
  approval_date: fixture.approval_date,
  source_displayed_current_stage: fixture.displayed_stage,
  source_system: fixture.source_system,
};

function requireId(value: unknown, operation: string): string {
  if (
    typeof value !== "object" ||
    value === null ||
    !("id" in value) ||
    typeof value.id !== "string"
  ) {
    throw new Error(`${operation} did not return a valid row id.`);
  }

  return value.id;
}

function stableJson(value: unknown): string {
  if (value === null || typeof value !== "object") {
    return JSON.stringify(value);
  }

  if (Array.isArray(value)) {
    return `[${value.map(stableJson).join(",")}]`;
  }

  const entries = Object.entries(value as Record<string, unknown>).sort(([left], [right]) =>
    left.localeCompare(right),
  );

  return `{${entries
    .map(([key, entryValue]) => `${JSON.stringify(key)}:${stableJson(entryValue)}`)
    .join(",")}}`;
}

function readSafeErrorField(error: unknown, field: string): string | undefined {
  if (typeof error !== "object" || error === null || !(field in error)) {
    return undefined;
  }

  const value = (error as Record<string, unknown>)[field];
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function createSafeDatabaseError(operation: string, error: unknown): SafeWorkflowError {
  const databaseMessage = readSafeErrorField(error, "message") ?? "Unknown database error.";
  const workflowError = new Error(`${operation}: ${databaseMessage}`) as SafeWorkflowError;
  const errorName = readSafeErrorField(error, "name");

  if (errorName) {
    workflowError.name = errorName;
  }
  workflowError.code = readSafeErrorField(error, "code");
  workflowError.details = readSafeErrorField(error, "details");
  workflowError.hint = readSafeErrorField(error, "hint");

  return workflowError;
}

function logDevelopmentIngestionError(error: unknown, workflowStep: string): void {
  if (process.env.NODE_ENV === "production") {
    return;
  }

  console.error("Development Seongsu ingestion failed", {
    workflowStep,
    name: readSafeErrorField(error, "name") ?? "Error",
    message: readSafeErrorField(error, "message") ?? "Unknown ingestion error.",
    code: readSafeErrorField(error, "code"),
    details: readSafeErrorField(error, "details"),
    hint: readSafeErrorField(error, "hint"),
  });
}

export async function runSeongsuZone1ManualIngestion(): Promise<SeongsuZone1IngestionResult> {
  const supabase = createAdminClient();
  let ingestionRunId: string | null = null;
  let currentStep = "resolve_area";

  try {
    const areaResponse = await supabase
      .from("areas")
      .select("id")
      .eq("slug", AREA_SLUG)
      .maybeSingle();

    if (areaResponse.error) {
      throw createSafeDatabaseError("Area lookup failed", areaResponse.error);
    }
    if (!areaResponse.data) {
      throw new Error(`Area ${AREA_SLUG} was not found.`);
    }
    const areaId = requireId(areaResponse.data, "Area lookup");

    currentStep = "resolve_source_document";
    const sourceDocumentResponse = await supabase
      .from("source_documents")
      .select("id, source_registry_id, source_url, title")
      .eq("source_identifier", SOURCE_IDENTIFIER)
      .maybeSingle();

    if (sourceDocumentResponse.error) {
      throw createSafeDatabaseError("Source document lookup failed", sourceDocumentResponse.error);
    }
    if (!sourceDocumentResponse.data) {
      throw new Error(`Source document ${SOURCE_IDENTIFIER} was not found.`);
    }
    const sourceDocumentId = requireId(sourceDocumentResponse.data, "Source document lookup");
    const sourceRegistryId = sourceDocumentResponse.data.source_registry_id;
    if (typeof sourceRegistryId !== "string") {
      throw new Error("Source document does not reference a valid source registry.");
    }

    currentStep = "validate_source_registry";
    const sourceRegistryResponse = await supabase
      .from("source_registry")
      .select("id, provider_name, dataset_name")
      .eq("id", sourceRegistryId)
      .maybeSingle();

    if (sourceRegistryResponse.error) {
      throw createSafeDatabaseError("Source registry lookup failed", sourceRegistryResponse.error);
    }
    if (
      !sourceRegistryResponse.data ||
      sourceRegistryResponse.data.provider_name !== "서울특별시" ||
      sourceRegistryResponse.data.dataset_name !== "정비사업 정보몽땅"
    ) {
      throw new Error("Source document does not belong to the expected Seoul source registry.");
    }

    currentStep = "create_ingestion_run";
    const startedAt = new Date().toISOString();
    const runResponse = await supabase
      .from("ingestion_runs")
      .insert({
        source_registry_id: sourceRegistryId,
        retry_of_run_id: null,
        started_at: startedAt,
        finished_at: null,
        status: "running",
        collection_method: COLLECTION_METHOD,
        collector_version: COLLECTOR_VERSION,
        requested_scope: {
          area_slug: AREA_SLUG,
          source_identifier: SOURCE_IDENTIFIER,
          fact_type: FACT_TYPE,
          attribute_key: ATTRIBUTE_KEY,
        },
        attempt_number: 1,
        records_received: 0,
        records_failed: 0,
        error_code: null,
        error_summary: null,
        retry_after: null,
        retention_until: null,
      })
      .select("id")
      .single();

    if (runResponse.error) {
      throw createSafeDatabaseError("Ingestion run creation failed", runResponse.error);
    }
    ingestionRunId = requireId(runResponse.data, "Ingestion run creation");

    const insertAudit = async ({
      eventType,
      actorLabel,
      entityType,
      entityId,
      ingestionRunId: auditRunId,
      changeSummary,
      reason,
    }: AuditInput) => {
      const auditResponse = await supabase.from("audit_logs").insert({
        event_type: eventType,
        actor_type: "system",
        actor_label: actorLabel,
        entity_type: entityType,
        entity_id: entityId,
        ingestion_run_id: auditRunId,
        publication_batch_id: null,
        before_hash: null,
        after_hash: null,
        change_summary: changeSummary,
        reason,
        occurred_at: new Date().toISOString(),
      });

      if (auditResponse.error) {
        throw createSafeDatabaseError(`Audit insert for ${eventType} failed`, auditResponse.error);
      }
    };

    currentStep = "insert_audit_log";
    await insertAudit({
      eventType: "ingestion_started",
      actorLabel: "phase2-server-v1",
      entityType: "ingestion_run",
      entityId: ingestionRunId,
      ingestionRunId,
      changeSummary: { status: "running", collection_method: COLLECTION_METHOD },
      reason: "Development fixture ingestion attempt started.",
    });

    currentStep = "insert_raw_observation";
    const fetchedAt = new Date().toISOString();
    const rawResponse = await supabase
      .from("raw_observations")
      .insert({
        ingestion_run_id: ingestionRunId,
        source_document_id: sourceDocumentId,
        provider_record_key: `${SOURCE_IDENTIFIER}:${ATTRIBUTE_KEY}:${ingestionRunId}`,
        fetched_at: fetchedAt,
        collection_method: COLLECTION_METHOD,
        payload: {
          source_system: fixture.source_system,
          project_title: fixture.project_title,
          area_slug: fixture.area_slug,
          displayed_stage: fixture.displayed_stage,
          approval_date: fixture.approval_date,
          source_identifier: fixture.source_identifier,
          source_url: sourceDocumentResponse.data.source_url,
          observation_method: "server_fixture_validation",
        },
        storage_uri: null,
        content_hash: null,
        http_status: null,
        parser_candidate_version: PARSER_VERSION,
        retention_until: null,
      })
      .select("id")
      .single();

    if (rawResponse.error) {
      throw createSafeDatabaseError("Raw observation insert failed", rawResponse.error);
    }
    const rawObservationId = requireId(rawResponse.data, "Raw observation insert");

    currentStep = "insert_audit_log";
    await insertAudit({
      eventType: "raw_observation_recorded",
      actorLabel: "phase2-server-v1",
      entityType: "raw_observation",
      entityId: rawObservationId,
      ingestionRunId,
      changeSummary: { source_document_id: sourceDocumentId },
      reason: "Structured server fixture observation recorded.",
    });

    currentStep = "insert_normalized_observation";
    const normalizedResponse = await supabase
      .from("normalized_observations")
      .insert({
        raw_observation_id: rawObservationId,
        area_id: areaId,
        fact_type: FACT_TYPE,
        attribute_key: ATTRIBUTE_KEY,
        normalized_value: normalizedValue,
        unit: null,
        effective_date: EFFECTIVE_DATE,
        parser_version: PARSER_VERSION,
        confidence_level: "high",
        verification_status: "review_required",
        deduplication_key: `${AREA_SLUG}:${FACT_TYPE}:${ATTRIBUTE_KEY}:${EFFECTIVE_DATE}`,
        conflict_group_id: null,
        stale_after: null,
        superseded_by_id: null,
      })
      .select("id")
      .single();

    if (normalizedResponse.error) {
      throw createSafeDatabaseError(
        "Normalized observation insert failed",
        normalizedResponse.error,
      );
    }
    const normalizedObservationId = requireId(
      normalizedResponse.data,
      "Normalized observation insert",
    );

    currentStep = "insert_audit_log";
    await insertAudit({
      eventType: "normalized_observation_created",
      actorLabel: "phase2-server-v1",
      entityType: "normalized_observation",
      entityId: normalizedObservationId,
      ingestionRunId,
      changeSummary: { verification_status: "review_required", confidence_level: "high" },
      reason: "Critical project-stage fixture normalized for human review.",
    });

    currentStep = "find_existing_published_fact";
    const publishedFactResponse = await supabase
      .from("published_facts")
      .select("id, published_value, effective_from")
      .eq("area_id", areaId)
      .eq("fact_type", FACT_TYPE)
      .eq("attribute_key", ATTRIBUTE_KEY)
      .eq("verification_status", "verified")
      .is("effective_to", null)
      .order("effective_from", { ascending: false, nullsFirst: false })
      .limit(1)
      .maybeSingle();

    if (publishedFactResponse.error) {
      throw createSafeDatabaseError("Published fact lookup failed", publishedFactResponse.error);
    }
    const existingFact = publishedFactResponse.data as PublishedFactRow | null;
    if (existingFact && typeof existingFact.id !== "string") {
      throw new Error("Published fact lookup returned an invalid row.");
    }

    const valueChanged = existingFact
      ? stableJson(existingFact.published_value) !== stableJson(normalizedValue)
      : true;
    const effectiveDateChanged = existingFact
      ? existingFact.effective_from !== EFFECTIVE_DATE
      : true;
    const differenceSummary = {
      has_existing_published_fact: existingFact !== null,
      value_changed: valueChanged,
      effective_date_changed: effectiveDateChanged,
      critical_change: true,
      reason: "Critical project-stage observations require human review.",
    };

    currentStep = "create_review_record";
    const reviewResponse = await supabase
      .from("review_records")
      .insert({
        normalized_observation_id: normalizedObservationId,
        review_type: "critical_stage_change",
        status: "requested",
        previous_published_fact_id: existingFact?.id ?? null,
        proposed_value: normalizedValue,
        difference_summary: differenceSummary,
        threshold_rule_version: "phase2-critical-stage-v1",
        reviewer_label: null,
        decision: null,
        decision_reason: null,
        requested_at: new Date().toISOString(),
        reviewed_at: null,
        last_verified_at: null,
      })
      .select("id")
      .single();

    if (reviewResponse.error) {
      throw createSafeDatabaseError("Review request insert failed", reviewResponse.error);
    }
    const reviewRecordId = requireId(reviewResponse.data, "Review request insert");

    currentStep = "insert_audit_log";
    await insertAudit({
      eventType: "review_requested",
      actorLabel: "phase2-server-v1",
      entityType: "review_record",
      entityId: reviewRecordId,
      ingestionRunId,
      changeSummary: differenceSummary,
      reason: "Critical project-stage observation requires human review before publication.",
    });

    currentStep = "finalize_ingestion_run";
    const finishedAt = new Date().toISOString();
    const completedRunResponse = await supabase
      .from("ingestion_runs")
      .update({
        finished_at: finishedAt,
        status: "succeeded",
        records_received: 1,
        records_failed: 0,
        error_code: null,
        error_summary: null,
      })
      .eq("id", ingestionRunId)
      .select("id")
      .single();

    if (completedRunResponse.error) {
      throw createSafeDatabaseError(
        "Ingestion run completion failed",
        completedRunResponse.error,
      );
    }
    requireId(completedRunResponse.data, "Ingestion run completion");

    currentStep = "insert_audit_log";
    await insertAudit({
      eventType: "ingestion_succeeded",
      actorLabel: "phase2-server-v1",
      entityType: "ingestion_run",
      entityId: ingestionRunId,
      ingestionRunId,
      changeSummary: { status: "succeeded", records_received: 1, records_failed: 0 },
      reason: "Development fixture ingestion completed and awaits human review.",
    });

    return {
      ingestionRunId,
      rawObservationId,
      normalizedObservationId,
      reviewRecordId,
      valueChanged,
      status: "succeeded",
    };
  } catch (error) {
    if (ingestionRunId) {
      const failedAt = new Date().toISOString();
      const safeSummary = `Seongsu fixture ingestion failed during ${currentStep}.`;
      const failedRunResponse = await supabase
        .from("ingestion_runs")
        .update({
          finished_at: failedAt,
          status: "failed",
          records_failed: 1,
          error_code: "SEONGSU_FIXTURE_INGESTION_FAILED",
          error_summary: safeSummary,
        })
        .eq("id", ingestionRunId);

      if (failedRunResponse.error) {
        logDevelopmentIngestionError(
          createSafeDatabaseError(
            "Best-effort ingestion failure-state update failed",
            failedRunResponse.error,
          ),
          "finalize_failed_ingestion_run",
        );
      }
    }

    logDevelopmentIngestionError(error, currentStep);
    throw error;
  }
}
