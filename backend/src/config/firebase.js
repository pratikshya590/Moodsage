const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// On your laptop: reads serviceAccountKey.json
// On Render (cloud): reads the key from an environment variable
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
} else {
  serviceAccount = require('../../serviceAccountKey.json');
}

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();   // the Firestore database
const auth = getAuth();      // used to check login tokens

module.exports = { db, auth };