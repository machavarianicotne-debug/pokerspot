// Firebase Cloud Messaging service worker — handles Web Push while the app is
// in the background / closed. Config mirrors firebase_options.dart (web).
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD7bS_QkOtwFdspxq3IlyTSCPJll3hGEy8',
  authDomain: 'pokerspot.firebaseapp.com',
  projectId: 'pokerspot',
  messagingSenderId: '398276701103',
  appId: '1:398276701103:web:8d79a49e01203c95d71d5a',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const n = payload.notification || {};
  self.registration.showNotification(n.title || 'PokerSpot', {
    body: n.body || '',
    icon: '/icons/Icon-192.png',
  });
});
