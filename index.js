import * as admin from "firebase-admin";
import { onDocumentUpdated, onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/* ==========================
 *  موجودة لديك (لا تغيّرها)
 * ========================== */
export const onPurchaseRequestStatusChanged = onDocumentUpdated(
  "purchaseRequests/{reqId}",
  async (event) => {
    const before = event.data?.before.data() || {};
    const after  = event.data?.after.data()  || {};
    const reqId  = event.params.reqId as string;

    const prev = before.status;
    const curr = after.status;
    if (!curr || prev === curr) return;

    const buyerUid  = after.userUid as string | undefined;
    const companyId = after.companyId as string | undefined;
    const title     = (after.title as string) || "Property";
    const propId    = (after.propId as string) || "";
    const chatId    = (after.chatId as string) || ""; // من الدوك

    if (!buyerUid) return;

    // 1) إشعار داخل Firestore
    await db.collection("users").doc(buyerUid)
      .collection("notifications").add({
        title: curr === "accepted" ? "تم قبول طلبك" :
               curr === "rejected" ? "تم رفض طلبك" : "تحديث الطلب",
        body: `الحالة الآن: ${curr} لعقار "${title}"`,
        type: "Deals",
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        reqId, companyId: companyId || "", propId,
        action: curr === "accepted" ? "open_chat" : "open_request",
        chatId,
      });

    // 2) Push
    const tokensSnap = await db.collection("users").doc(buyerUid)
      .collection("tokens").get();
    const tokens = tokensSnap.docs.map((d)=> d.id).filter(Boolean);
    if (tokens.length === 0) return;

    const payload = {
      notification: {
        title: curr === "accepted" ? "تم قبول طلبك" :
               curr === "rejected" ? "تم رفض طلبك" : "تحديث الطلب",
        body: `الحالة الآن: ${curr} لعقار "${title}"`,
      },
      data: {
        type: "request_status",
        status: curr,
        reqId,
        companyId: companyId || "",
        propId,
        chatId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    await messaging.sendEachForMulticast({ tokens, ...payload });
  }
);

/* ======================================================
 *  1) Callable: إنشاء إعلان + خصم الرصيد (سيرفر فقط)
 *  يستقبل:
 *   - property: كائن الإعلان (title/description/address/price/... إلخ)
 *  يعتمد uid من context.auth (لا يسمح بإنشاء نيابة عن غيره)
 * ====================================================== */
export const createPropertyAndConsume = onCall(async (request) => {
  const context = request;
  if (!context.auth) {
    throw new Error("unauthenticated");
  }

  const companyUid = context.auth.uid;
  const prop = (request.data?.property ?? {}) as Record<string, any>;

  // فحوصات أساسية
  if (!prop.title || !prop.description || !prop.address) {
    throw new Error("invalid-argument: missing fields");
  }
  if (typeof prop.price !== "number") {
    throw new Error("invalid-argument: price must be number");
  }

  const companyRef = db.collection("companies").doc(companyUid);
  const propsCol = companyRef.collection("properties");

  await db.runTransaction(async (tx) => {
    const cSnap = await tx.get(companyRef);
    if (!cSnap.exists) throw new Error("failed-precondition: company missing");

    const c = cSnap.data() || {};
    const unlimited: boolean = !!c.unlimited;
    const quota: number = Number(c.quotaRemaining || 0);
    const status: string = c.planStatus || "none"; // 'active'|'pending'|'none'
    const expiresAt: number = c.planExpiresAt ? c.planExpiresAt.toMillis() : 0;
    const now = Date.now();

    if (status !== "active") throw new Error("plan not active");
    if (!unlimited && quota <= 0) throw new Error("no quota left");
    if (!unlimited && expiresAt && now > expiresAt) throw new Error("plan expired");

    const newDoc = propsCol.doc();
    tx.set(newDoc, {
      ...prop,
      ownerUid: companyUid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (!unlimited) {
      tx.update(companyRef, { quotaRemaining: quota - 1 });
    }
  });

  return { ok: true };
});

/* ======================================================
 *  2) Trigger: حارس على أي إنشاء مباشر (client write)
 *  إن كان غير مسموح → تحذف الإعلان / أو تخصم الرصيد
 * ====================================================== */
export const guardAndConsumeOnCreate = onDocumentCreated(
  "companies/{companyUid}/properties/{propId}",
  async (event) => {
    const { companyUid } = event.params as { companyUid: string };
    const snap = event.data;
    if (!snap) return;

    const companyRef = db.collection("companies").doc(companyUid);

    await db.runTransaction(async (tx) => {
      const cs = await tx.get(companyRef);
      if (!cs.exists) {
        tx.delete(snap.ref);
        return;
      }

      const c = cs.data() || {};
      const unlimited: boolean = !!c.unlimited;
      const quota: number = Number(c.quotaRemaining || 0);
      const status: string = c.planStatus || "none";
      const expiresAt: number = c.planExpiresAt ? c.planExpiresAt.toMillis() : 0;
      const now = Date.now();

      const invalid = (status !== "active") ||
                      (!unlimited && quota <= 0) ||
                      (!unlimited && expiresAt && now > expiresAt);

      if (invalid) {
        // تجاوز رصيد/خطة غير صالحة → نحذف
        tx.delete(snap.ref);
        return;
      }

      if (!unlimited) {
        tx.update(companyRef, { quotaRemaining: quota - 1 });
      }
    });
  }
);

/* ======================================================
 *  3) Callable: اعتماد خطة وتفعيلها (لوحة الإدارة)
 *  data = { companyUid, planType }  planType: '5'|'15'|'30'|'unlimited'
 *  ملاحظة: لاحقًا فعّل تحقّق أدمن عبر Custom Claims
 * ====================================================== */
export const approvePlan = onCall(async (request) => {
  if (!request.auth) throw new Error("unauthenticated");

  const companyUid = request.data?.companyUid as string;
  const planType   = request.data?.planType as "5" | "15" | "30" | "unlimited";

  if (!companyUid || !["5", "15", "30", "unlimited"].includes(planType)) {
    throw new Error("invalid-argument");
  }

  const companyRef = db.collection("companies").doc(companyUid);

  await db.runTransaction(async (tx) => {
    const s = await tx.get(companyRef);
    if (!s.exists) throw new Error("not-found: company");

    let update: any = {
      planType,
      planStatus: "active",
      unlimited: false,
      planExpiresAt: admin.firestore.FieldValue.delete(),
    };

    if (planType === "unlimited") {
      const expires = admin.firestore.Timestamp.fromMillis(
        Date.now() + 365 * 24 * 60 * 60 * 1000
      );
      update = { ...update, unlimited: true, planExpiresAt: expires };
    } else {
      const map: Record<string, number> = { "5": 5, "15": 15, "30": 30 };
      update = { ...update, quotaRemaining: map[planType] };
    }
    tx.set(companyRef, update, { merge: true });
  });

  return { ok: true };
});
