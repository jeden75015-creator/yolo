exports.notifyParticipants = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const convId = context.params.conversationId;
    const convRef = admin.firestore().collection('conversations').doc(convId);
    const convDoc = await convRef.get();
    if (!convDoc.exists) return null;

    const users = convDoc.data().users || [];
    const payload = {
      notification: {
        title: 'Nouveau message 💬',
        body: message.text || '',
      },
    };

    // envoie à tous les tokens des users (à gérer dans users/{uid}/fcmToken)
    // ...
    return null;
  });
