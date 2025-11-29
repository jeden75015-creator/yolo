/* -------------------------------------------------------------------------- */
/* 🎯 IMPORTS                                                                 */
/* -------------------------------------------------------------------------- */

import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();
const db = admin.firestore();

/* -------------------------------------------------------------------------- */
/* 📨 1 — NOTIFICATION MESSAGE PRIVE                                          */
/* -------------------------------------------------------------------------- */

export const notifyNewMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const msg = snapshot.data();
    if (!msg) return null;

    const senderId = msg.senderId;
    const receiverId = msg.receiverId;
    const text = msg.text ?? "";

    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data()?.name || "Quelqu’un" : "Quelqu’un";

    const receiverDoc = await db.collection("users").doc(receiverId).get();
    const token = receiverDoc.exists ? receiverDoc.data()?.fcmToken : null;

    if (!token) {
      console.log("⚠️ Aucun token FCM trouvé pour", receiverId);
      return null;
    }

    await admin.messaging().sendToDevice(token, {
      notification: {
        title: `${senderName} t’a envoyé un message 💬`,
        body: text.substring(0, 80),
      },
      data: {
        senderId,
        chatId: event.params.chatId,
      },
    });

    console.log("✅ Notification message privé envoyée !");
    return null;
  }
);

/* -------------------------------------------------------------------------- */
/* 💬 2 — NOTIFICATION CHAT D’ACTIVITE                                       */
/* -------------------------------------------------------------------------- */

export const notifyParticipantsOnNewActivityMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const msg = snapshot.data();
    if (!msg?.text || !msg?.userId) return null;

    const convId = event.params.conversationId;
    const convDoc = await db.collection("conversations").doc(convId).get();
    if (!convDoc.exists) return null;

    const conv = convDoc.data()!;
    const users: string[] = conv.users || [];
    const titreActivite = conv.fromActivite || "Activité";

    const senderDoc = await db.collection("users").doc(msg.userId).get();
    const senderName = senderDoc.exists ? senderDoc.data()?.name || "Quelqu’un" : "Quelqu’un";

    const tokens: string[] = [];

    for (const uid of users) {
      if (uid === msg.userId) continue;
      const doc = await db.collection("users").doc(uid).get();
      const token = doc.exists ? doc.data()?.fcmToken : null;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) return null;

    await admin.messaging().sendToDevice(tokens, {
      notification: {
        title: `💬 ${senderName} - ${titreActivite}`,
        body: msg.text.substring(0, 80) + (msg.text.length > 80 ? "…" : ""),
      },
      data: {
        conversationId: convId,
        fromUserId: msg.userId,
      },
    });

    console.log("✅ Notification activité envoyée");
    return null;
  }
);

/* -------------------------------------------------------------------------- */
/* 🤝 3 — AUTOMATISATION ACCEPTATION D’AMITIÉ                                */
/* -------------------------------------------------------------------------- */

export const onFriendRequestAccepted = onDocumentUpdated(
  "notifications/{notifId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return null;

    if (before.status === after.status) return null;
    if (after.status !== "accepted") return null;

    const fromUserId = after.fromUserId;
    const toUserId = after.toUserId;

    const batch = db.batch();

    batch.set(
      db.collection("users").doc(fromUserId).collection("amis").doc(toUserId),
      { addedAt: admin.firestore.FieldValue.serverTimestamp(), accepted: true }
    );

    batch.set(
      db.collection("users").doc(toUserId).collection("amis").doc(fromUserId),
      { addedAt: admin.firestore.FieldValue.serverTimestamp(), accepted: true }
    );

    batch.update(
      db.collection("notifications").doc(event.params.notifId),
      { processedAt: admin.firestore.FieldValue.serverTimestamp() }
    );

    await batch.commit();
    console.log("🤝 Amitié mutuelle enregistrée !");
    return null;
  }
);

/* -------------------------------------------------------------------------- */
/* 👋 4 — NOTIFICATION NOUVEAU PARTICIPANT                                   */
/* -------------------------------------------------------------------------- */

export const notifyNewParticipant = onDocumentUpdated(
  "activites/{activiteId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return null;

    const beforeList: string[] = before.participants || [];
    const afterList: string[] = after.participants || [];

    const added = afterList.filter((id) => !beforeList.includes(id));
    if (added.length === 0) return null;

    const newUserId = added[0];

    const userDoc = await db.collection("users").doc(newUserId).get();
    const userName = userDoc.exists ? userDoc.data()?.name || "Quelqu’un" : "Quelqu’un";

    const tokens: string[] = [];
    for (const uid of afterList) {
      if (uid === newUserId) continue;
      const doc = await db.collection("users").doc(uid).get();
      const token = doc.exists ? doc.data()?.fcmToken : null;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) return null;

    await admin.messaging().sendToDevice(tokens, {
      notification: {
        title: "👋 Nouveau participant",
        body: `${userName} a rejoint "${after.titre}"`,
      },
      data: {
        activiteId: event.params.activiteId,
        newUserId,
      },
    });

    console.log("👋 Notification participant envoyée !");
    return null;
  }
);

/* -------------------------------------------------------------------------- */
/* ⏰ MESSAGE AUTOMATIQUE 3H AVANT ACTIVITÉ                                   */
/* -------------------------------------------------------------------------- */

export const notify3hBeforeActivity = onSchedule(
  {
    schedule: "every 10 minutes",
    timeZone: "Europe/Paris",
  },
  async (_event) => {
    const now = new Date();
    const snap = await db.collection("activites").get();

    if (snap.empty) return; // ⬅️ plus de null

    for (const doc of snap.docs) {
      const act = doc.data();
      const actId = doc.id;

      if (!act.date) continue;
      if (act.notified3hBefore === true) continue;

      const actDate: Date = act.date.toDate();
      const diffMin = Math.round((actDate.getTime() - now.getTime()) / 60000);

      if (diffMin < 190 && diffMin > 170) {
        console.log("⏰ Message 3h avant pour", actId);

        const heure =
          `${String(actDate.getHours()).padStart(2, "0")}h` +
          `${String(actDate.getMinutes()).padStart(2, "0")}`;

        await db
          .collection("activites")
          .doc(actId)
          .collection("chat")
          .add({
            userId: "system",
            system: true,
            message:
              `Votre activité commence dans 3 heures.\n` +
              `📍 Adresse : ${act.adresse}\n` +
              `🗺 Région : ${act.region}\n` +
              `🕒 Début : ${heure}`,
            createdAt: admin.firestore.Timestamp.now(),
          });

        await db.collection("activites").doc(actId).update({
          notified3hBefore: true,
        });
      }
    }

    return; // ⬅️ encore : jamais null
  }
);
