import * as admin from "firebase-admin";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

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
    const chatId    = (after.chatId as string) || ""; // ✅ من الدوك

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
        chatId, // ✅ الحقيقي
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
        chatId, // ✅ الحقيقي
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    await messaging.sendEachForMulticast({ tokens, ...payload });
  }
);
