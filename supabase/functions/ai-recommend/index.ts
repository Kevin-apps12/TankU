// Supabase Edge Function: ai-recommend
//
// Gathers a tank's profile + recent readings (respecting the caller's RLS)
// and asks Venice AI (OpenAI-compatible API) for reef-keeping recommendations.
// The Venice API key lives only in this function's secrets — never in the app.
//
// Deploy:
//   supabase functions deploy ai-recommend
// Set secrets:
//   supabase secrets set VENICE_API_KEY=your_key
//   supabase secrets set VENICE_MODEL=llama-3.3-70b   (optional)
//
// Invoked from the app via supabase.functions.invoke('ai-recommend', ...).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VENICE_URL = "https://api.venice.ai/api/v1/chat/completions";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/// Picks a usable Venice text model. Uses VENICE_MODEL if it's valid for this
/// key, otherwise a preferred capable model, otherwise the first available.
async function pickModel(
  apiKey: string,
  preferred?: string,
): Promise<string | null> {
  const fallback = preferred && preferred.length > 0 ? preferred : null;
  try {
    const res = await fetch("https://api.venice.ai/api/v1/models?type=text", {
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    if (!res.ok) return fallback;
    const body = await res.json();
    const ids: string[] = (body?.data ?? [])
      .map((m: { id?: string }) => m.id)
      .filter((id: unknown): id is string => typeof id === "string");
    if (ids.length === 0) return fallback;
    if (preferred && ids.includes(preferred)) return preferred;
    const prefs = [
      "llama-3.3-70b",
      "qwen3-235b",
      "llama-3.1-405b",
      "mistral-31-24b",
      "deepseek-r1-671b",
    ];
    for (const p of prefs) {
      if (ids.includes(p)) return p;
    }
    return ids[0];
  } catch (_) {
    return fallback;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader) return json({ error: "Missing Authorization." }, 401);

    const reqBody = await req.json().catch(() => ({}));
    const tank_id = reqBody?.tank_id;
    if (!tank_id) return json({ error: "tank_id is required." }, 400);

    // Prior conversation turns from the app (memory). Validated + capped.
    const history: Array<{ role: string; content: string }> =
      Array.isArray(reqBody?.messages)
        ? reqBody.messages
            .filter(
              (m: { role?: string; content?: string }) =>
                (m?.role === "user" || m?.role === "assistant") &&
                typeof m?.content === "string",
            )
            .slice(-20)
        : [];

    // Client bound to the caller's JWT → RLS ensures they only read their tank.
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const [
      { data: tank },
      equipment,
      livestock,
      dosing,
      feedings,
      health,
      readings,
    ] = await Promise.all([
      supabase.from("tanks").select("*").eq("id", tank_id).single(),
      supabase.from("equipment").select("*").eq("tank_id", tank_id),
      supabase.from("livestock").select("*").eq("tank_id", tank_id),
      supabase.from("dosing").select("*").eq("tank_id", tank_id),
      supabase.from("feedings").select("*").eq("tank_id", tank_id),
      supabase
        .from("health_logs")
        .select("*")
        .eq("tank_id", tank_id)
        .order("observed_at", { ascending: false })
        .limit(20),
      supabase
        .from("parameter_readings")
        .select("*")
        .eq("tank_id", tank_id)
        .order("measured_at", { ascending: false })
        .limit(120),
    ]);

    if (!tank) return json({ error: "Tank not found or not yours." }, 404);

    // Latest reading per parameter + a short recent history.
    const latest: Record<string, { value: number; measured_at: string }> = {};
    for (const r of readings.data ?? []) {
      if (!latest[r.parameter_key]) {
        latest[r.parameter_key] = { value: r.value, measured_at: r.measured_at };
      }
    }

    const habitat: string = tank.habitat ?? "saltwater";

    const context = {
      tank: {
        name: tank.name,
        volume_liters: tank.volume_liters,
        habitat,
        type: tank.tank_type,
        started_on: tank.started_on,
        notes: tank.notes,
      },
      equipment: (equipment.data ?? []).map((e) => ({
        name: e.name,
        category: e.category,
        brand: e.brand,
        model: e.model,
      })),
      livestock: (livestock.data ?? []).map((l) => ({
        name: l.name,
        kind: l.kind,
        species: l.species,
        quantity: l.quantity,
      })),
      dosing: (dosing.data ?? []).map((d) => ({
        product: d.product,
        amount: d.amount,
        unit: d.unit,
        frequency: d.frequency,
        targets: d.target_parameter,
      })),
      feeding: (feedings.data ?? []).map((f) => ({
        food: f.food,
        amount: f.amount,
        frequency: f.frequency,
        notes: f.notes,
      })),
      health_journal: (health.data ?? []).map((h) => ({
        rating_out_of_10: h.rating,
        notes: h.notes,
        at: h.observed_at,
      })),
      latest_readings: latest,
      recent_history: (readings.data ?? []).slice(0, 60).map((r) => ({
        parameter: r.parameter_key,
        value: r.value,
        at: r.measured_at,
      })),
    };

    // Prefer the standard name; fall back to "TankU" (the name this project's
    // secret was originally saved under).
    const apiKey =
      Deno.env.get("VENICE_API_KEY") ?? Deno.env.get("TankU");
    if (!apiKey) {
      return json(
        { error: "Venice API key secret is not set (VENICE_API_KEY)." },
        500,
      );
    }
    const model = await pickModel(apiKey, Deno.env.get("VENICE_MODEL"));
    if (!model) {
      return json(
        { error: "No Venice text model available for this API key." },
        502,
      );
    }

    const ranges: Record<string, string> = {
      saltwater:
        "saltwater reef target ranges (Alk 8-9.5 dKH, Ca 400-450 ppm, " +
        "Mg 1250-1350 ppm, pH 7.9-8.4, NO3 2-10 ppm, PO4 0.03-0.10 ppm, " +
        "temp 24.5-26.5C, salinity 1.025/35ppt)",
      freshwater:
        "freshwater target ranges (pH 6.5-7.5, Ammonia 0, Nitrite 0, " +
        "NO3 <20 ppm, GH 4-12 dGH, KH 3-8 dKH, PO4 <1 ppm, temp 24-27C); " +
        "planted tanks tolerate higher nitrate and benefit from CO2",
      pond:
        "pond/koi target ranges (pH 7.0-8.5, Ammonia 0, Nitrite 0, " +
        "NO3 <40 ppm, KH 4-8 dKH, dissolved O2 6-9 mg/L, PO4 <0.5 ppm); " +
        "watch temperature swings and oxygen in warm weather",
    };

    const advisorRole = habitat === "freshwater"
      ? "freshwater aquarium"
      : habitat === "pond"
      ? "pond and koi"
      : "saltwater reef aquarium";
    const habitatRanges = ranges[habitat] ?? ranges.saltwater;

    const systemPrompt =
      `You are an expert ${advisorRole} advisor. You are given a tank's full ` +
      "profile: volume, habitat and type, equipment, livestock, dosing, " +
      "feeding schedule, the owner's health journal (1-10 ratings + notes), " +
      "the latest water parameters, and recent parameter history. " +
      `This tank's habitat is ${habitat}. Reference common ${habitatRanges}. ` +
      "For your FIRST analysis of the tank, respond in markdown with these " +
      "sections:\n" +
      "## What's going on — a short read of the tank's overall state and any " +
      "notable trends (improving/declining, swings, correlations between " +
      "parameters, livestock load vs nutrients, feeding vs nitrate/phosphate).\n" +
      "## Watch-outs — anything out of range or risky, most urgent first.\n" +
      "## Suggestions — specific, actionable adjustments (dosing amounts, " +
      "feeding, husbandry, equipment) to improve or maintain the tank.\n" +
      "For any FOLLOW-UP questions, answer directly and conversationally " +
      "(skip the section headers). Always stay concise and practical, tailor " +
      "advice to the actual livestock and data present, and reference the " +
      "target ranges when relevant. If data is sparse, say what to test or log " +
      "next. Remind the user to verify major changes before acting.";

    const aiRes = await fetch(VENICE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: systemPrompt },
          {
            role: "user",
            content:
              "Here is my tank data as JSON:\n\n" +
              JSON.stringify(context, null, 2) +
              "\n\nGive your analysis.",
          },
          // The ongoing conversation (initial analysis, then follow-ups).
          ...history,
        ],
        temperature: 0.4,
        max_tokens: 900,
      }),
    });

    if (!aiRes.ok) {
      const detail = await aiRes.text();
      return json(
        { error: `Venice AI error (${aiRes.status}): ${detail}` },
        502,
      );
    }

    const data = await aiRes.json();
    const recommendation: string =
      data?.choices?.[0]?.message?.content ?? "No recommendation returned.";

    return json({ recommendation });
  } catch (e) {
    return json({ error: `Unexpected error: ${e}` }, 500);
  }
});
