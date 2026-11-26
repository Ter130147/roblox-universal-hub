export default {
async fetch(request, env) {
const url = new URL(request.url);
const adminSecret = env.ADMIN_SECRET || "TER-ADMIN-2700";

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// 1. สุ่มคีย์ใหม่ + ระบุจำนวนวัน + ตั้งหมดอายุอัตโนมัติใน KV
if (url.pathname === "/generate") {
  if (url.searchParams.get("secret") !== adminSecret) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  const days = Math.max(0.01, parseFloat(url.searchParams.get("days") || "1"));
  const rand = () => Math.random().toString(36).substring(2, 6).toUpperCase();
  const key = `TER-${rand()}-${rand()}-${rand()}`;
  const expiresAt = Date.now() + Math.floor(days * 86400 * 1000);
  const ttlSeconds = Math.max(60, Math.ceil(days * 86400) + 3600);

  await env.KEYS_DB.put(
    key,
    JSON.stringify({
      key,
      days,
      expiresAt,
      hwid: null,
      createdAt: Date.now(),
    }),
    { expirationTtl: ttlSeconds }
  );

  return json({ ok: true, key, days, expiresAt });
}

// 2. ตรวจสอบคีย์ + ล็อกเครื่อง HWID
if (url.pathname === "/verify") {
  const key = (url.searchParams.get("key") || "").trim().toUpperCase();
  const hwid = (url.searchParams.get("hwid") || "").trim();

  if (!key || !hwid) {
    return json({ ok: false, message: "กรุณากรอก Key ให้ครบถ้วน" }, 400);
  }

  const raw = await env.KEYS_DB.get(key);
  if (!raw) {
    return json({ ok: false, message: "ไม่พบ Key นี้ในระบบ" }, 404);
  }

  const record = JSON.parse(raw);
  if (Date.now() > record.expiresAt) {
    return json({ ok: false, message: "Key นี้หมดอายุแล้ว" }, 403);
  }

  if (!record.hwid) {
    record.hwid = hwid;
    await env.KEYS_DB.put(key, JSON.stringify(record));
  } else if (record.hwid !== hwid) {
    return json({ ok: false, message: "Key นี้ถูกผูกกับเครื่องอื่นแล้ว" }, 403);
  }

  const hoursLeft = Math.max(0, (record.expiresAt - Date.now()) / 3600000).toFixed(1);
  return json({ ok: true, message: "ผ่านการตรวจสอบ", hoursLeft });
}

// 3. รีเซ็ตเครื่อง (HWID)
if (url.pathname === "/reset") {
  if (url.searchParams.get("secret") !== adminSecret) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  const key = (url.searchParams.get("key") || "").trim().toUpperCase();
  const raw = await env.KEYS_DB.get(key);
  if (!raw) return json({ ok: false, message: "Key not found" }, 404);

  const record = JSON.parse(raw);
  record.hwid = null;
  await env.KEYS_DB.put(key, JSON.stringify(record));
  return json({ ok: true, message: "Reset HWID success", key });
}

// 4. ดูรายการคีย์ทั้งหมดใน KV
if (url.pathname === "/list") {
  if (url.searchParams.get("secret") !== adminSecret) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  const listed = await env.KEYS_DB.list();
  const items = [];
  for (const entry of listed.keys) {
    const raw = await env.KEYS_DB.get(entry.name);
    if (raw) {
      const rec = JSON.parse(raw);
      items.push({
        key: rec.key,
        days: rec.days,
        hwidBound: Boolean(rec.hwid),
        expired: Date.now() > rec.expiresAt,
        hoursLeft: Math.max(0, (rec.expiresAt - Date.now()) / 3600000).toFixed(1),
      });
    }
  }
  return json({ ok: true, count: items.length, keys: items });
}

// 5. ลบ/แบนคีย์ออกจาก KV
if (url.pathname === "/delete") {
  if (url.searchParams.get("secret") !== adminSecret) {
    return json({ ok: false, message: "Unauthorized" }, 401);
  }
  const key = (url.searchParams.get("key") || "").trim().toUpperCase();
  if (!key) return json({ ok: false, message: "Missing key" }, 400);
  await env.KEYS_DB.delete(key);
  return json({ ok: true, message: "Deleted key", key });
}

return json({ ok: true, service: "Ter Universal Hub Key API" });
},
};