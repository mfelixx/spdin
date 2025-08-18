/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

/* eslint quotes: "off", max-len: "off", object-curly-spacing: "off" */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteUserByAdmin = functions.https.onCall(async (data, context) => {
  const callerUid = context.auth.uid;

  const callerDoc = await admin.firestore().collection("users").doc(callerUid).get();

  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Hanya admin yang boleh menghapus akun.");
  }

  const uidToDelete = data.uid;

  try {
    await admin.auth().deleteUser(uidToDelete);
    await admin.firestore().collection("users").doc(uidToDelete).delete();
    return {success: true};
  } catch (e) {
    throw new functions.https.HttpsError("internal", e.message);
  }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
