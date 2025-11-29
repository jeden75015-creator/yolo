// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBWvnrOKW7VEE9EB_gRBufyUoXnSYs0HyU",
  projectId: "yolo-d90ce",
  messagingSenderId: "606774801473",
  appId: "1:606774801473:web:0ea73627bd81b09c30c2c0",
});

// Vérifie que le worker est bien actif
const messaging = firebase.messaging();
console.log("✅ Firebase Messaging Service Worker actif !");

